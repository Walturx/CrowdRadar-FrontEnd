import 'package:crowdradar/core/models/alerta.dart';
import 'package:crowdradar/core/models/analitica.dart';
import 'package:crowdradar/core/models/categoria_lugar.dart';
import 'package:crowdradar/core/models/enum_api.dart';
import 'package:crowdradar/core/models/favorito.dart';
import 'package:crowdradar/core/models/lugar_detalle.dart';
import 'package:crowdradar/core/models/lugar_resumen.dart';
import 'package:crowdradar/core/models/moderacion.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/models/reporte_saturacion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('enum_api', () {
    test('valorApi converts camelCase names to SCREAMING_SNAKE', () {
      expect(valorApi(NivelSaturacion.tranquilo), 'TRANQUILO');
      expect(valorApi(CategoriaLugar.centroComercial), 'CENTRO_COMERCIAL');
    });

    test('enumDesdeApi finds a value or returns null', () {
      expect(enumDesdeApi(CategoriaLugar.values, 'PLAYA'), CategoriaLugar.playa);
      expect(enumDesdeApi(CategoriaLugar.values, 'CENTRO_COMERCIAL'),
          CategoriaLugar.centroComercial);
      expect(enumDesdeApi(CategoriaLugar.values, 'NADA'), isNull);
      expect(enumDesdeApi(CategoriaLugar.values, null), isNull);
    });
  });

  group('NivelSaturacion.desdeApi', () {
    test('maps the three levels', () {
      expect(NivelSaturacion.desdeApi('MODERADO'), NivelSaturacion.moderado);
      expect(NivelSaturacion.desdeApi('SATURADO'), NivelSaturacion.saturado);
    });

    test('null and unknown values mean sinInformacion', () {
      expect(NivelSaturacion.desdeApi(null), NivelSaturacion.sinInformacion);
      expect(NivelSaturacion.desdeApi('XYZ'), NivelSaturacion.sinInformacion);
    });
  });

  group('lugares', () {
    test('LugarResumen parses coordinates, level and optional distance', () {
      final l = LugarResumen.fromJson({
        'id': 3,
        'nombre': 'Parque Kennedy',
        'categoria': 'PARQUE',
        'latitud': -12.1,
        'longitud': -77,
        'saturacion': 'SATURADO',
        'distanciaMetros': 350,
      });

      expect(l.id, 3);
      expect(l.categoria, CategoriaLugar.parque);
      expect(l.longitud, -77.0);
      expect(l.saturacion, NivelSaturacion.saturado);
      expect(l.distanciaMetros, 350.0);
    });

    test('LugarResumen without saturation or distance', () {
      final l = LugarResumen.fromJson({
        'id': 4,
        'nombre': 'Mercado',
        'categoria': 'MERCADO',
        'latitud': 1.5,
        'longitud': 2.5,
        'saturacion': null,
      });

      expect(l.saturacion, NivelSaturacion.sinInformacion);
      expect(l.distanciaMetros, isNull);
    });

    test('LugarDetalle parses nested saturation and favorite flags', () {
      final d = LugarDetalle.fromJson({
        'id': 3,
        'nombre': 'Parque Kennedy',
        'categoria': 'PARQUE',
        'direccion': 'Av. Larco',
        'latitud': -12.1,
        'longitud': -77.0,
        'abiertoAhora': true,
        'horarioAtencion': '06:00-22:00',
        'saturacion': {
          'nivel': 'MODERADO',
          'actualizadoEn': '2026-10-05T12:00:00.000Z',
          'reportesRecientes': 4,
          'mensaje': 'Afluencia media',
        },
        'esFavorito': true,
        'alertasActivadas': true,
      });

      expect(d.saturacion.nivel, NivelSaturacion.moderado);
      expect(d.saturacion.actualizadoEn, DateTime.utc(2026, 10, 5, 12));
      expect(d.saturacion.reportesRecientes, 4);
      expect(d.abiertoAhora, true);
      expect(d.esFavorito, true);
      expect(d.alertasActivadas, true);
    });

    test('LugarDetalle without saturation block defaults to sinInformacion', () {
      final d = LugarDetalle.fromJson({
        'id': 9,
        'nombre': 'Playa',
        'categoria': 'PLAYA',
        'latitud': 0,
        'longitud': 0,
      });

      expect(d.saturacion.nivel, NivelSaturacion.sinInformacion);
      expect(d.saturacion.reportesRecientes, 0);
      expect(d.esFavorito, false);
    });
  });

  group('reportes', () {
    test('ReporteCreado exposes karma earned and total', () {
      final r = ReporteCreado.fromJson({
        'reporte': {
          'id': 10,
          'lugarId': 3,
          'nivel': 'SATURADO',
          'fechaHora': '2026-10-05T12:00:00.000Z',
        },
        'karma': {'puntosGanados': 10, 'total': 120, 'motivoSinPuntos': null},
      });

      expect(r.reporte.nivel, NivelSaturacion.saturado);
      expect(r.puntosGanados, 10);
      expect(r.totalKarma, 120);
      expect(r.motivoSinPuntos, isNull);
    });

    test('ReporteCreado with daily cap carries the reason', () {
      final r = ReporteCreado.fromJson({
        'reporte': {
          'id': 11,
          'lugarId': 3,
          'nivel': 'TRANQUILO',
          'fechaHora': '2026-10-05T12:00:00.000Z',
        },
        'karma': {
          'puntosGanados': 0,
          'total': 120,
          'motivoSinPuntos': 'TOPE_DIARIO',
        },
      });

      expect(r.puntosGanados, 0);
      expect(r.motivoSinPuntos, 'TOPE_DIARIO');
    });
  });

  group('favoritos y alertas', () {
    test('Favorito', () {
      final f = Favorito.fromJson({
        'lugarId': 3,
        'nombre': 'Parque',
        'categoria': 'PARQUE',
        'saturacion': 'TRANQUILO',
        'alertasActivadas': true,
      });

      expect(f.lugarId, 3);
      expect(f.saturacion, NivelSaturacion.tranquilo);
      expect(f.alertasActivadas, true);
    });

    test('Alerta', () {
      final a = Alerta.fromJson({
        'id': 1,
        'lugarId': 3,
        'lugarNombre': 'Parque',
        'nivelAnterior': 'TRANQUILO',
        'nivelNuevo': 'SATURADO',
        'mensaje': 'Ahora está saturado',
        'leida': false,
        'fechaHora': '2026-10-05T12:00:00.000Z',
      });

      expect(a.nivelAnterior, NivelSaturacion.tranquilo);
      expect(a.nivelNuevo, NivelSaturacion.saturado);
      expect(a.leida, false);
    });
  });

  group('analitica', () {
    test('SerieSaturacion parses points and the no-data flag', () {
      final s = SerieSaturacion.fromJson({
        'puntos': [
          {'etiqueta': '10:00', 'valor': 2.5},
          {'etiqueta': '11:00', 'valor': 3},
        ],
      });

      expect(s.puntos.map((p) => p.valor), [2.5, 3.0]);
      expect(s.sinDatos, false);

      final vacia = SerieSaturacion.fromJson({'sinDatos': true, 'mensaje': 'Sin datos'});
      expect(vacia.puntos, isEmpty);
      expect(vacia.sinDatos, true);
      expect(vacia.mensaje, 'Sin datos');
    });

    test('ComparacionPeriodos and MejorHorario', () {
      final c = ComparacionPeriodos.fromJson({
        'periodoA': {
          'puntos': [
            {'etiqueta': 'L', 'valor': 1}
          ]
        },
        'periodoB': {'sinDatos': true},
      });
      expect(c.periodoA.puntos, hasLength(1));
      expect(c.periodoB.sinDatos, true);

      final m = MejorHorario.fromJson({
        'franjas': [
          {'horaInicio': 8, 'horaFin': 10, 'nivel': 'TRANQUILO'}
        ],
      });
      expect(m.franjas.single.horaInicio, 8);
      expect(m.franjas.single.nivel, NivelSaturacion.tranquilo);
      expect(m.sinDatos, false);
    });
  });

  group('moderacion', () {
    test('ReporteDenunciado and UsuarioAdmin', () {
      final r = ReporteDenunciado.fromJson({
        'reporteId': 5,
        'lugarNombre': 'Parque',
        'nivel': 'SATURADO',
        'totalDenuncias': 3,
      });
      expect(r.totalDenuncias, 3);

      final u = UsuarioAdmin.fromJson({
        'id': 8,
        'nombre': 'Luz',
        'apellido': 'Vega',
        'email': 'luz@test.com',
        'status': 'SUSPENDIDO',
        'puntosKarma': 40,
      });
      expect(u.estaSuspendido, true);
      expect(u.puntosKarma, 40);

      expect(
        UsuarioAdmin.fromJson({
          'id': 9,
          'nombre': 'a',
          'apellido': 'b',
          'email': 'c',
          'status': 'ACTIVO',
        }).estaSuspendido,
        false,
      );
    });
  });
}
