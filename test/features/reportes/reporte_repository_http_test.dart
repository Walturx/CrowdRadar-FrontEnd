import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/session/session_service.dart';
import 'package:crowdradar/features/reportes/data/reporte_repository_http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../fakes/http_falso.dart';

Map<String, dynamic> _creado({int puntos = 10, String? motivo}) => {
  'message': 'Reporte registrado',
  'data': {
    'reporte': {
      'id': 5,
      'lugarId': 7,
      'nivel': 'MODERADO',
      'fechaHora': '2026-10-05T12:00:00.000Z',
    },
    'karma': {'puntosGanados': puntos, 'total': 130, 'motivoSinPuntos': motivo},
    'saturacionLugar': {
      'nivel': 'MODERADO',
      'actualizadoEn': '2026-10-05T12:00:00.000Z',
    },
  },
};

Map<String, dynamic> _item(int id, {String? motivo}) => {
  'id': id,
  'lugar': {'id': 7, 'nombre': 'Parque Kennedy'},
  'nivel': 'SATURADO',
  'fechaHora': '2026-10-05T12:00:00.000Z',
  'estado': 'ACTIVO',
  'puntosOtorgados': motivo == null ? 10 : 0,
  'motivoSinPuntos': motivo,
};

void main() {
  late SessionService sesion;
  http.Request? visto;

  ReporteRepositoryHttp repo(int status, Object? body) {
    visto = null;
    return ReporteRepositoryHttp(
      apiClientPrueba((r) async {
        visto = r;
        return respuestaJson(status, body);
      }, sesion),
    );
  }

  Matcher falla(int status, String? code) => throwsA(
    isA<ApiException>()
        .having((e) => e.status, 'status', status)
        .having((e) => e.code, 'code', code),
  );

  setUp(() => sesion = SessionService.instance..reiniciar());
  tearDown(() => sesion.reiniciar());

  group('reportar', () {
    test(
      'POSTs lugarId and the wire nivel, maps the 201 karma outcome',
      () async {
        final r = repo(201, _creado());

        final res = await r.reportar(7, NivelSaturacion.moderado);

        expect(visto!.method, 'POST');
        expect(visto!.url.path, '/api/reportes');
        expect(visto!.body, '{"lugarId":7,"nivel":"MODERADO"}');
        expect(res.puntosGanados, 10);
        expect(res.totalKarma, 130);
        expect(res.reporte.nivel, NivelSaturacion.moderado);
        expect(res.motivoSinPuntos, isNull);
      },
    );

    test('daily cap: 201 with zero points carries the reason', () async {
      final r = repo(201, _creado(puntos: 0, motivo: 'TOPE_DIARIO'));

      final res = await r.reportar(7, NivelSaturacion.saturado);

      expect(res.puntosGanados, 0);
      expect(res.motivoSinPuntos, 'TOPE_DIARIO');
    });

    test(
      '422 REPORTE_EN_ESPERA, 404 and 400 surface as ApiException',
      () async {
        await expectLater(
          repo(422, {
            'message': 'En espera',
            'code': 'REPORTE_EN_ESPERA',
          }).reportar(7, NivelSaturacion.moderado),
          falla(422, 'REPORTE_EN_ESPERA'),
        );
        await expectLater(
          repo(404, {
            'message': 'No existe',
            'code': 'LUGAR_NO_ENCONTRADO',
          }).reportar(99, NivelSaturacion.moderado),
          falla(404, 'LUGAR_NO_ENCONTRADO'),
        );
        await expectLater(
          repo(400, {
            'message': 'Datos inválidos.',
            'code': 'VALIDACION_FALLIDA',
          }).reportar(7, NivelSaturacion.moderado),
          falla(400, 'VALIDACION_FALLIDA'),
        );
      },
    );

    test('a network failure is sinConexion', () async {
      final r = ReporteRepositoryHttp(
        apiClientPrueba((_) async => throw http.ClientException('x'), sesion),
      );

      await expectLater(
        r.reportar(7, NivelSaturacion.moderado),
        throwsA(
          isA<ApiException>().having((e) => e.esSinConexion, 'off', true),
        ),
      );
    });
  });

  group('listarMios', () {
    test(
      'sends page and size and maps lugar name, points and estado',
      () async {
        final r = repo(200, {
          'message': 'ok',
          'data': {
            'items': [_item(2), _item(1, motivo: 'TOPE_DIARIO')],
            'page': 2,
            'size': 2,
            'total': 5,
            'totalPaginas': 3,
          },
        });

        final p = await r.listarMios(page: 2, size: 2);

        expect(visto!.url.path, '/api/reportes/mios');
        expect(visto!.url.queryParameters, {'page': '2', 'size': '2'});
        expect(p.items.first.lugarNombre, 'Parque Kennedy');
        expect(p.items.first.lugarId, 7);
        expect(p.items.first.puntosOtorgados, 10);
        expect(p.items.first.estado, 'ACTIVO');
        expect(p.items.last.puntosOtorgados, 0);
        expect(p.items.last.motivoSinPuntos, 'TOPE_DIARIO');
        expect(p.hayMas, isTrue);
      },
    );

    test('an empty history is a page without items', () async {
      final r = repo(200, {
        'message': 'Aún no tienes reportes',
        'data': {
          'items': [],
          'page': 1,
          'size': 20,
          'total': 0,
          'totalPaginas': 0,
        },
      });

      final p = await r.listarMios();

      expect(visto!.url.queryParameters, {'page': '1', 'size': '20'});
      expect(p.items, isEmpty);
      expect(p.hayMas, isFalse);
    });
  });
}
