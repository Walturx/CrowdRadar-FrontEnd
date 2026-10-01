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

  test('fechaIso pads month and day', () {
    expect(fechaIso(DateTime(2026, 3, 7)), '2026-03-07');
  });
}
