import 'package:crowdradar/core/models/analitica.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/session/session_service.dart';
import 'package:crowdradar/features/analitica/data/analitica_repository_http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../fakes/http_falso.dart';

List<Map<String, dynamic>> _slots(double valor) => [
  for (var h = 0; h < 24; h++) {'hora': h, 'valor': valor, 'muestras': 3},
];

void main() {
  late SessionService sesion;
  http.Request? visto;

  AnaliticaRepositoryHttp repo(int status, Object? body) {
    visto = null;
    return AnaliticaRepositoryHttp(
      apiClientPrueba((r) async {
        visto = r;
        return respuestaJson(status, body);
      }, sesion),
    );
  }

  setUp(() => sesion = SessionService.instance..reiniciar());
  tearDown(() => sesion.reiniciar());

  group('historial', () {
    test(
      'serializes dates as YYYY-MM-DD and agrupacion, maps hayDatos',
      () async {
        final r = repo(200, {
          'message': 'ok',
          'data': {
            'puntos': [
              {'etiqueta': '09:00', 'valor': 2.5, 'muestras': 4},
              {'etiqueta': '14:00', 'valor': 1.0, 'muestras': 2},
            ],
            'hayDatos': true,
            'mensaje': null,
          },
        });

        final s = await r.historial(
          7,
          desde: DateTime(2026, 10, 1),
          hasta: DateTime(2026, 10, 9),
          agrupacion: AgrupacionHistorial.dia,
        );

        expect(visto!.url.path, '/api/lugares/7/historial');
        expect(visto!.url.queryParameters, {
          'desde': '2026-10-01',
          'hasta': '2026-10-09',
          'agrupacion': 'DIA',
        });
        expect(s.sinDatos, isFalse);
        expect(s.puntos.map((p) => p.etiqueta), ['09:00', '14:00']);
        expect(s.puntos.first.muestras, 4);
      },
    );

    test('hayDatos=false becomes sinDatos with the backend message', () async {
      final r = repo(200, {
        'message': 'ok',
        'data': {
          'puntos': [],
          'hayDatos': false,
          'mensaje':
              'No existe información histórica disponible para este lugar.',
        },
      });

      final s = await r.historial(7);

      expect(visto!.url.queryParameters, isEmpty);
      expect(s.sinDatos, isTrue);
      expect(s.mensaje, contains('No existe información histórica'));
    });

    test('400 RANGO_FECHAS_INVALIDO and 404 are ApiExceptions', () async {
      await expectLater(
        repo(400, {
          'message': 'Rango inválido',
          'code': 'RANGO_FECHAS_INVALIDO',
        }).historial(7),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            'RANGO_FECHAS_INVALIDO',
          ),
        ),
      );
      await expectLater(
        repo(404, {
          'message': 'No existe',
          'code': 'LUGAR_NO_ENCONTRADO',
        }).historial(99),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 404)),
      );
    });
  });

  group('comparar', () {
    test(
      'serializes the six inputs and maps periods, diferencias, resumen',
      () async {
        final r = repo(200, {
          'message': 'ok',
          'data': {
            'periodoA': _slots(1),
            'periodoB': _slots(2),
            'diferencias': [
              for (var h = 0; h < 24; h++) {'hora': h, 'diferencia': 1.0},
            ],
            'resumen':
                'Los fines de semana la afluencia sube entre 11:00 y 19:00.',
            'suficiente': true,
            'mensaje': null,
          },
        });

        final c = await r.comparar(
          7,
          desdeA: DateTime(2026, 9, 1),
          hastaA: DateTime(2026, 9, 15),
          diasA: 'LABORABLES',
          desdeB: DateTime(2026, 9, 1),
          hastaB: DateTime(2026, 9, 15),
          diasB: 'FIN_DE_SEMANA',
        );

        expect(visto!.url.path, '/api/lugares/7/comparar');
        expect(visto!.url.queryParameters, {
          'desdeA': '2026-09-01',
          'hastaA': '2026-09-15',
          'diasA': 'LABORABLES',
          'desdeB': '2026-09-01',
          'hastaB': '2026-09-15',
          'diasB': 'FIN_DE_SEMANA',
        });
        expect(c.sinDatos, isFalse);
        expect(c.periodoA.puntos, hasLength(24));
        expect(c.periodoA.puntos[9].etiqueta, '09:00');
        expect(c.periodoB.puntos.first.valor, 2.0);
        expect(c.diferencias.first.diferencia, 1.0);
        expect(c.resumen, contains('11:00 y 19:00'));
      },
    );

    test('suficiente=false becomes sinDatos with the message', () async {
      final r = repo(200, {
        'message': 'ok',
        'data': {
          'periodoA': [],
          'periodoB': [],
          'diferencias': [],
          'resumen': null,
          'suficiente': false,
          'mensaje':
              'No existen datos suficientes para realizar la comparación.',
        },
      });

      final c = await r.comparar(
        7,
        desdeA: DateTime(2026, 9, 1),
        hastaA: DateTime(2026, 9, 15),
        desdeB: DateTime(2026, 9, 1),
        hastaB: DateTime(2026, 9, 15),
      );

      expect(visto!.url.queryParameters.containsKey('diasA'), isFalse);
      expect(c.sinDatos, isTrue);
      expect(c.mensaje, contains('datos suficientes'));
    });
  });

  group('mejorHorario', () {
    test('sends dias and semanas, maps recomendaciones into franjas', () async {
      final r = repo(200, {
        'message': 'ok',
        'data': {
          'recomendaciones': [
            {
              'horaInicio': 8,
              'horaFin': 9,
              'nivel': 'TRANQUILO',
              'promedio': 1.2,
              'muestras': 9,
            },
            {
              'horaInicio': 15,
              'horaFin': 16,
              'nivel': 'MODERADO',
              'promedio': 1.9,
              'muestras': 6,
            },
          ],
          'suficiente': true,
          'mensaje': null,
        },
      });

      final m = await r.mejorHorario(7, dias: 'TODOS', semanas: 6);

      expect(visto!.url.path, '/api/lugares/7/mejor-horario');
      expect(visto!.url.queryParameters, {'dias': 'TODOS', 'semanas': '6'});
      expect(m.sinDatos, isFalse);
      expect(m.franjas, hasLength(2));
      expect(m.franjas.first.horaInicio, 8);
      expect(m.franjas.first.nivel, NivelSaturacion.tranquilo);
      expect(m.franjas.first.promedio, 1.2);
      expect(m.franjas.first.muestras, 9);
    });

    test('suficiente=false becomes sinDatos with the message', () async {
      final r = repo(200, {
        'message': 'ok',
        'data': {
          'recomendaciones': [],
          'suficiente': false,
          'mensaje':
              'No existen datos suficientes para generar la recomendación.',
        },
      });

      final m = await r.mejorHorario(7);

      expect(visto!.url.queryParameters, {'semanas': '4'});
      expect(m.sinDatos, isTrue);
      expect(m.franjas, isEmpty);
      expect(m.mensaje, contains('generar la recomendación'));
    });
  });
}
