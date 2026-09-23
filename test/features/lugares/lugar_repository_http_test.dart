import 'package:crowdradar/core/map/tipos_mapa.dart';
import 'package:crowdradar/core/models/categoria_lugar.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/session/session_service.dart';
import 'package:crowdradar/features/lugares/data/lugar_repository_http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../fakes/http_falso.dart';

const _lugarJson = {
  'id': 7,
  'nombre': 'Parque Kennedy',
  'categoria': 'PARQUE',
  'latitud': -12.1219,
  'longitud': -77.0297,
  'saturacion': 'MODERADO',
};

const _bbox = LimitesMapa(
  norte: -12.10,
  sur: -12.14,
  este: -77.00,
  oeste: -77.06,
);

void main() {
  late SessionService sesion;
  http.Request? visto;

  LugarRepositoryHttp repo(int status, Object? body) {
    visto = null;
    return LugarRepositoryHttp(
      apiClientPrueba((r) async {
        visto = r;
        return respuestaJson(status, body);
      }, sesion),
    );
  }

  setUp(() => sesion = SessionService.instance..reiniciar());
  tearDown(() => sesion.reiniciar());

  group('buscar', () {
    test(
      'GETs /api/lugares and parses items with the server message',
      () async {
        final r = repo(200, {
          'message': 'ok',
          'data': {
            'items': [
              _lugarJson,
              {..._lugarJson, 'id': 8, 'saturacion': 'SIN_INFORMACION'},
            ],
            'total': 2,
          },
        });

        final res = await r.buscar(bbox: _bbox);

        expect(visto!.method, 'GET');
        expect(visto!.url.path, '/api/lugares');
        expect(res.items.map((l) => l.id), [7, 8]);
        expect(res.items.first.saturacion, NivelSaturacion.moderado);
        expect(res.items.first.categoria, CategoriaLugar.parque);
        expect(res.items.last.saturacion, NivelSaturacion.sinInformacion);
      },
    );

    test('serializes bbox as minLng,minLat,maxLng,maxLat', () async {
      final r = repo(200, {
        'data': {'items': []},
      });

      await r.buscar(bbox: _bbox);

      expect(visto!.url.queryParameters, {'bbox': '-77.06,-12.14,-77.0,-12.1'});
    });

    test(
      'serializes q, categoria, nivel and limite; omits the absent ones',
      () async {
        final r = repo(200, {
          'data': {'items': []},
        });

        await r.buscar(
          q: 'Par',
          categoria: CategoriaLugar.centroComercial,
          nivel: NivelSaturacion.sinInformacion,
          limite: 20,
        );

        expect(visto!.url.queryParameters, {
          'q': 'Par',
          'categoria': 'CENTRO_COMERCIAL',
          'nivel': 'SIN_INFORMACION',
          'limite': '20',
        });
      },
    );

    test('an empty result keeps the server message', () async {
      final r = repo(200, {
        'message': 'No hay lugares en esta zona.',
        'data': {'items': [], 'total': 0},
      });

      final res = await r.buscar(bbox: _bbox);

      expect(res.estaVacia, isTrue);
      expect(res.mensaje, 'No hay lugares en esta zona.');
    });

    test('400 becomes an ApiException with its code', () async {
      final r = repo(400, {
        'message': 'Datos inválidos',
        'code': 'VALIDACION_FALLIDA',
        'errors': [
          {'campo': 'q', 'mensaje': 'Mínimo 2 caracteres'},
        ],
      });

      await expectLater(
        r.buscar(q: 'a'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.status, 'status', 400)
              .having((e) => e.code, 'code', 'VALIDACION_FALLIDA')
              .having((e) => e.errors.single.campo, 'campo', 'q'),
        ),
      );
    });

    test('a network failure becomes ApiException.sinConexion', () async {
      final r = LugarRepositoryHttp(
        apiClientPrueba(
          (_) async => throw http.ClientException('caído'),
          sesion,
        ),
      );

      await expectLater(
        r.buscar(bbox: _bbox),
        throwsA(
          isA<ApiException>().having((e) => e.esSinConexion, 'offline', true),
        ),
      );
    });
  });

  group('obtener', () {
    test('GETs /api/lugares/:id and maps the detail', () async {
      final r = repo(200, {
        'data': {
          ..._lugarJson,
          'direccion': 'Av. Larco 345, Miraflores',
          'horarioAtencion': '06:00-22:00',
          'abiertoAhora': true,
          'saturacion': {
            'nivel': 'MODERADO',
            'actualizadoEn': '2026-10-04T10:00:00.000Z',
            'reportesRecientes': 18,
            'mensaje': null,
          },
          'esFavorito': true,
        },
      });

      final d = await r.obtener(7);

      expect(visto!.url.path, '/api/lugares/7');
      expect(d.nombre, 'Parque Kennedy');
      expect(d.direccion, 'Av. Larco 345, Miraflores');
      expect(d.horarioAtencion, '06:00-22:00');
      expect(d.saturacion.nivel, NivelSaturacion.moderado);
      expect(d.saturacion.reportesRecientes, 18);
      expect(d.esFavorito, isTrue);
    });

    test('404 LUGAR_NO_ENCONTRADO surfaces as ApiException 404', () async {
      final r = repo(404, {
        'message': 'No se pudo obtener la información del lugar.',
        'code': 'LUGAR_NO_ENCONTRADO',
      });

      await expectLater(
        r.obtener(99),
        throwsA(
          isA<ApiException>()
              .having((e) => e.status, 'status', 404)
              .having((e) => e.code, 'code', 'LUGAR_NO_ENCONTRADO'),
        ),
      );
    });

    test('a network failure becomes ApiException.sinConexion', () async {
      final r = LugarRepositoryHttp(
        apiClientPrueba(
          (_) async => throw http.ClientException('caído'),
          sesion,
        ),
      );

      await expectLater(
        r.obtener(1),
        throwsA(
          isA<ApiException>().having((e) => e.esSinConexion, 'offline', true),
        ),
      );
    });
  });
}
