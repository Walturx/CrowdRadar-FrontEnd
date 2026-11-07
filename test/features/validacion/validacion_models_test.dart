import 'package:crowdradar/core/models/enum_api.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/models/tier_usuario.dart';
import 'package:crowdradar/core/models/validacion.dart';
import 'package:flutter_test/flutter_test.dart';

import 'json_validacion.dart';

void main() {
  group('Confiabilidad', () {
    test('ALTA carries the weighted percentage and raw counts', () {
      final c = Confiabilidad.fromJson(confiabilidadJson());

      expect(c.nivel, NivelConfiabilidad.alta);
      expect(c.porcentaje, 85.71);
      expect((c.confirmaciones, c.rechazos), (18, 3));
      expect(c.advertencia, isNull);
    });

    test('INSUFICIENTE has a null percentage; BAJA keeps the warning', () {
      final i = Confiabilidad.fromJson(
        confiabilidadJson(porcentaje: null, nivel: 'INSUFICIENTE'),
      );
      final b = Confiabilidad.fromJson(
        confiabilidadJson(
          porcentaje: 38.46,
          nivel: 'BAJA',
          advertencia: advertenciaBaja,
        ),
      );

      expect(i.nivel, NivelConfiabilidad.insuficiente);
      expect(i.porcentaje, isNull);
      expect(b.nivel, NivelConfiabilidad.baja);
      expect(b.advertencia, advertenciaBaja);
    });

    test('an integer percentage (e.g. 100) is read as a double', () {
      final c = Confiabilidad.fromJson(confiabilidadJson(porcentaje: 100));

      expect(c.porcentaje, 100.0);
    });

    test('an unknown level degrades to insuficiente', () {
      final c = Confiabilidad.fromJson(confiabilidadJson(nivel: 'RARO'));

      expect(c.nivel, NivelConfiabilidad.insuficiente);
    });
  });

  group('ReportePendiente', () {
    test('reads the nested lugar and confiabilidad', () {
      final r = ReportePendiente.fromJson(pendienteJson());

      expect(r.id, 31);
      expect(r.lugar.id, 7);
      expect(r.lugar.nombre, 'Parque Kennedy');
      expect(r.nivel, NivelSaturacion.saturado);
      expect(r.distanciaMetros, 420);
      expect(r.confiabilidad.nivel, NivelConfiabilidad.alta);
      expect(r.fechaHora, DateTime.utc(2026, 10, 5, 12));
    });
  });

  group('DetalleReporte', () {
    test('reads my vote, flags and estado', () {
      final d = DetalleReporte.fromJson(
        detalleJson(miValidacion: 'RECHAZAR', yaDenunciado: true),
      );

      expect(d.miValidacion, TipoAccionValidacion.rechazar);
      expect(d.yaDenunciado, isTrue);
      expect(d.esPropio, isFalse);
      expect(d.estadoValidacion, EstadoValidacion.validado);
      expect(d.lugar.nombre, 'Parque Kennedy');
    });

    test('miValidacion null means I have not voted', () {
      final d = DetalleReporte.fromJson(detalleJson(esPropio: true));

      expect(d.miValidacion, isNull);
      expect(d.esPropio, isTrue);
    });
  });

  group('ResultadoVoto', () {
    test('C3 maps the 201 data block without karma', () {
      final v = ResultadoVoto.fromJson(
        votoCreadoJson()['data'] as Map<String, dynamic>,
      );

      expect(v.accion, TipoAccionValidacion.confirmar);
      expect(v.estadoValidacion, EstadoValidacion.enValidacion);
      expect(v.confiabilidad.nivel, NivelConfiabilidad.alta);
    });

    ResultadoVoto conUsuario(Object? usuario) => ResultadoVoto.fromJson({
      ...votoCreadoJson()['data'] as Map<String, dynamic>,
      'usuario': usuario,
    });

    for (final (wire, tier) in [
      ('CROWD_BABY', TierUsuario.crowdBaby),
      ('CROWD_EXPLORER', TierUsuario.crowdExplorer),
      ('CROWD_COLLABORATOR', TierUsuario.crowdCollaborator),
      ('CROWD_ROYALTY', TierUsuario.crowdRoyalty),
    ]) {
      test('C7 usuario.tier $wire is the voter tier', () {
        expect(conUsuario(usuarioVotoJson(tier: wire)).tier, tier);
      });
    }

    test('S23 a missing usuario block means no tier, not Crowd Baby', () {
      final v = ResultadoVoto.fromJson(
        votoCreadoJson()['data'] as Map<String, dynamic>,
      );

      expect(v.tier, isNull);
      expect(conUsuario(null).tier, isNull);
    });

    test('S23 an unknown or missing tier value means no tier', () {
      expect(conUsuario(usuarioVotoJson(tier: 'CROWD_LEGEND')).tier, isNull);
      expect(conUsuario(usuarioVotoJson(tier: 'crowd_explorer')).tier, isNull);
      expect(conUsuario(usuarioVotoJson(tier: null)).tier, isNull);
      expect(conUsuario({'puntos': 120}).tier, isNull);
    });
  });

  test('motivo and estado wire values are SCREAMING_SNAKE', () {
    expect(
      valorApi(MotivoDenuncia.contenidoInapropiado),
      'CONTENIDO_INAPROPIADO',
    );
    expect(valorApi(EstadoValidacion.enValidacion), 'EN_VALIDACION');
  });

  group('EstadoReporteValidacion', () {
    test('reads estadoValidacion and the counts inside confiabilidad', () {
      final e = EstadoReporteValidacion.fromJson(estadoMioJson());

      expect(e.reporteId, 5);
      expect(e.estadoValidacion, EstadoValidacion.enValidacion);
      expect(e.confirmaciones, 1);
      expect(e.rechazos, 1);
      expect(e.lugar.nombre, 'Parque Kennedy');
      expect(e.nivel, NivelSaturacion.moderado);
    });

    test('SIN_VALIDACIONES maps too', () {
      final e = EstadoReporteValidacion.fromJson(
        estadoMioJson(estado: 'SIN_VALIDACIONES'),
      );

      expect(e.estadoValidacion, EstadoValidacion.sinValidaciones);
    });
  });
}
