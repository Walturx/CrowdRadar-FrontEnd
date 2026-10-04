import 'package:crowdradar/core/models/analitica.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/models/reporte_saturacion.dart';
import 'package:crowdradar/core/utils/formato_fecha.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReporteSaturacion', () {
    test('create response keeps the optional list fields null', () {
      final r = ReporteSaturacion.fromJson({
        'id': 1,
        'lugarId': 3,
        'nivel': 'SATURADO',
      });

      expect(r.lugarId, 3);
      expect(r.lugarNombre, isNull);
      expect(r.puntosOtorgados, isNull);
    });

    test('list item reads lugar{id,nombre}, points, reason and estado', () {
      final r = ReporteSaturacion.fromJson({
        'id': 2,
        'lugar': {'id': 9, 'nombre': 'Larcomar'},
        'nivel': 'TRANQUILO',
        'estado': 'ACTIVO',
        'puntosOtorgados': 0,
        'motivoSinPuntos': 'TOPE_DIARIO',
      });

      expect(r.lugarId, 9);
      expect(r.lugarNombre, 'Larcomar');
      expect(r.puntosOtorgados, 0);
      expect(r.motivoSinPuntos, 'TOPE_DIARIO');
      expect(r.estado, 'ACTIVO');
    });
  });

  group('analitica backend shapes', () {
    test('legacy sinDatos and the synthetic flag still parse', () {
      final s = SerieSaturacion.fromJson({'sinDatos': true, 'sintetico': true});

      expect(s.sinDatos, isTrue);
      expect(s.sintetico, isTrue);
    });

    test('franja hours accept "HH:00" strings', () {
      final f = FranjaHoraria.fromJson({
        'horaInicio': '09:00',
        'horaFin': '10:00',
        'nivel': 'MODERADO',
      });

      expect((f.horaInicio, f.horaFin), (9, 10));
      expect(f.nivel, NivelSaturacion.moderado);
      expect(f.promedio, isNull);
    });

    test('a comparison is sinDatos when either period lacks data', () {
      final c = ComparacionPeriodos.fromJson({
        'periodoA': {'sinDatos': true},
        'periodoB': [
          {'hora': 3, 'valor': 2, 'muestras': 5},
        ],
      });

      expect(c.sinDatos, isTrue);
      expect(c.periodoB.puntos.single.etiqueta, '03:00');
    });
  });

  group('tolerant analytics parsers (R3-606)', () {
    test('non-bool sinDatos / hayDatos / suficiente are treated as false', () {
      expect(SerieSaturacion.fromJson({'sinDatos': 'yes'}).sinDatos, isFalse);
      expect(SerieSaturacion.fromJson({'hayDatos': 'false'}).sinDatos, isFalse);
      expect(SerieSaturacion.fromJson({'hayDatos': 0}).sinDatos, isFalse);
      expect(SerieSaturacion.fromJson({'hayDatos': false}).sinDatos, isTrue);
      expect(MejorHorario.fromJson({'suficiente': 'no'}).sinDatos, isFalse);
      expect(MejorHorario.fromJson({'suficiente': false}).sinDatos, isTrue);
    });

    test('a non-string etiqueta becomes empty and never throws', () {
      expect(PuntoSerie.fromJson({'etiqueta': 5, 'valor': 2}).etiqueta, '');
      expect(PuntoSerie.fromJson({'valor': 2}).etiqueta, '');
      expect(PuntoSerie.fromJson({'hora': 9, 'valor': 2}).etiqueta, '09:00');
    });

    test('missing keys and wrong container types give empty values', () {
      final serie = SerieSaturacion.fromJson({'puntos': 'nope', 'mensaje': 42});
      expect(serie.puntos, isEmpty);
      expect(serie.mensaje, isNull);

      final comparacion = ComparacionPeriodos.fromJson({
        'diferencias': {'a': 1},
        'resumen': 3,
        'mensaje': false,
      });
      expect(comparacion.diferencias, isEmpty);
      expect(comparacion.resumen, isNull);
      expect(comparacion.mensaje, isNull);
      expect(comparacion.suficiente, isTrue);

      final horario = MejorHorario.fromJson({'recomendaciones': 'x'});
      expect(horario.franjas, isEmpty);
    });

    test(
      'a comparison is sinDatos when either period reports hayDatos false',
      () {
        final a = ComparacionPeriodos.fromJson({
          'periodoA': {'hayDatos': false},
          'periodoB': [
            {'hora': 0, 'valor': 1},
          ],
        });
        final b = ComparacionPeriodos.fromJson({
          'periodoA': [
            {'hora': 0, 'valor': 1},
          ],
          'periodoB': {'hayDatos': false},
        });
        final ok = ComparacionPeriodos.fromJson({
          'periodoA': [
            {'hora': 0, 'valor': 1},
          ],
          'periodoB': [
            {'hora': 0, 'valor': 2},
          ],
        });

        expect(a.sinDatos, isTrue);
        expect(b.sinDatos, isTrue);
        expect(ok.sinDatos, isFalse);
      },
    );

    test('diferenciaRespectoA is period B minus period A, negatives kept', () {
      final c = ComparacionPeriodos.fromJson({
        'diferencias': [
          {'hora': '09:00', 'diferencia': -0.5},
          {'hora': 10, 'diferencia': 0.75},
          {'hora': 11, 'diferencia': 'x'},
        ],
      });

      expect(c.diferencias.map((d) => d.diferenciaRespectoA), [-0.5, 0.75, 0]);
      expect(c.diferencias.first.hora, 9);
    });
  });

  test('fechaIso pads month and day', () {
    expect(fechaIso(DateTime(2026, 3, 7)), '2026-03-07');
  });
}
