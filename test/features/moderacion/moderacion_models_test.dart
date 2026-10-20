import 'package:crowdradar/core/models/categoria_lugar.dart';
import 'package:crowdradar/core/models/moderacion.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/models/validacion.dart';
import 'package:flutter_test/flutter_test.dart';

import 'json_moderacion.dart';

void main() {
  group('ReporteDenunciado', () {
    test('parses the backend row (nested lugar and autor)', () {
      final r = ReporteDenunciado.fromJson(reporteDenunciadoJson());

      expect(r.reporteId, 201);
      expect(r.lugar.nombre, 'Jockey Plaza');
      expect(r.lugar.categoria, CategoriaLugar.centroComercial);
      expect(r.autor.nombreCorto, 'Carlos M.');
      expect(r.nivel, NivelSaturacion.tranquilo);
      expect(r.pendientes, 4);
      expect(r.fechaHora, DateTime.utc(2026, 10, 5, 12));
      expect(r.ultimaDenunciaEn, DateTime.utc(2026, 10, 5, 12, 10));
    });

    test('missing nested blocks do not throw', () {
      final r = ReporteDenunciado.fromJson({'reporteId': 3});

      expect(r.lugar.nombre, '');
      expect(r.autor.nombreCorto, '');
      expect(r.pendientes, 0);
      expect(r.fechaHora, isNull);
    });
  });

  group('DetalleReporteDenunciado', () {
    test('parses motivos, estado and the author email', () {
      final d = DetalleReporteDenunciado.fromJson(detalleReporteJson());

      expect(d.estado, EstadoReporteModerado.activo);
      expect(d.autor.email, 'carlos.mendez@correo.pe');
      expect(d.pendientes, 4);
      expect(d.motivos.map((m) => (m.motivo, m.total)).toList(), [
        (MotivoDenuncia.informacionFalsa, 2),
        (MotivoDenuncia.contenidoInapropiado, 1),
        (MotivoDenuncia.spam, 1),
      ]);
    });

    test('ELIMINADO and an unknown motivo fall back safely', () {
      final json = detalleReporteJson(estado: 'ELIMINADO')
        ..['motivos'] = [
          {'motivo': 'RARO', 'total': 1},
        ];
      final d = DetalleReporteDenunciado.fromJson(json);

      expect(d.estado, EstadoReporteModerado.eliminado);
      expect(d.motivos.single.motivo, MotivoDenuncia.otro);
    });
  });

  test('ResolucionReporte parses estado and denunciasResueltas', () {
    final r = ResolucionReporte.fromJson(resolucionJson());

    expect(r.reporteId, 201);
    expect(r.estado, EstadoReporteModerado.eliminado);
    expect(r.denunciasResueltas, 4);
  });

  test('DecisionModeracion wire values are MANTENER and ELIMINAR', () {
    expect(DecisionModeracion.mantener.valorApi, 'MANTENER');
    expect(DecisionModeracion.eliminar.valorApi, 'ELIMINAR');
  });

  group('UsuarioAdmin', () {
    test('an active user has no sancion', () {
      final u = UsuarioAdmin.fromJson(usuarioJson());

      expect(u.rol, 'USUARIO');
      expect(u.esAdmin, isFalse);
      expect(u.status, EstadoCuenta.activo);
      expect(u.estaSuspendido, isFalse);
      expect(u.sancionVigente, isNull);
      expect(u.puntosKarma, 40);
    });

    test('a suspended user carries the vigente sancion', () {
      final u = UsuarioAdmin.fromJson(
        usuarioJson(status: 'SUSPENDIDO', sancion: sancionJson()),
      );

      expect(u.estaSuspendido, isTrue);
      expect(u.sancionVigente!.dias, 7);
      expect(u.sancionVigente!.motivo, 'Spam reiterado en reportes');
      expect(u.sancionVigente!.fechaFin, DateTime.utc(2026, 10, 12, 12));
    });

    test('ADMIN rol is recognised', () {
      expect(
        UsuarioAdmin.fromJson({...usuarioJson(), 'rol': 'ADMIN'}).esAdmin,
        isTrue,
      );
    });

    test('DetalleUsuarioAdmin adds the report counters', () {
      final d = DetalleUsuarioAdmin.fromJson(detalleUsuarioJson());

      expect(d.reportesPublicados, 32);
      expect(d.reportesDenunciados, 5);
      expect(d.email, 'lucia.paredes@correo.pe');
    });
  });

  group('SancionVigente.diasRestantes', () {
    final sancion = SancionVigente.fromJson(sancionJson());

    test('counts started days up (faltan N dias)', () {
      expect(sancion.diasRestantes(DateTime.utc(2026, 10, 7, 12)), 5);
      expect(sancion.diasRestantes(DateTime.utc(2026, 10, 10, 13)), 2);
    });

    test('less than a day left still says 1', () {
      expect(sancion.diasRestantes(DateTime.utc(2026, 10, 12, 6)), 1);
    });

    test('an expired sancion has none left', () {
      expect(sancion.diasRestantes(DateTime.utc(2026, 10, 12, 12)), 0);
      expect(sancion.diasRestantes(DateTime.utc(2026, 11, 1)), 0);
    });
  });
}
