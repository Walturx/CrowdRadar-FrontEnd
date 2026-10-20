import 'dart:convert';

import 'package:crowdradar/core/models/moderacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/session/session_service.dart';
import 'package:crowdradar/features/moderacion/data/moderacion_repository_http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../fakes/http_falso.dart';
import 'json_moderacion.dart';

void main() {
  late SessionService sesion;
  http.Request? visto;

  ModeracionRepositoryHttp repo(int status, Object? body) {
    visto = null;
    return ModeracionRepositoryHttp(
      apiClientPrueba((r) async {
        visto = r;
        return respuestaJson(status, body);
      }, sesion),
    );
  }

  Map<String, dynamic> cuerpo() =>
      jsonDecode(visto!.body) as Map<String, dynamic>;

  Matcher falla(int status, String? code) => throwsA(
    isA<ApiException>()
        .having((e) => e.status, 'status', status)
        .having((e) => e.code, 'code', code),
  );

  Map<String, dynamic> error(String code) => {'message': 'x', 'code': code};

  setUp(() => sesion = SessionService.instance..reiniciar());
  tearDown(() => sesion.reiniciar());

  group('reportesDenunciados', () {
    test('GETs the queue with page and size and parses the rows', () async {
      final r = repo(200, paginaJson([reporteDenunciadoJson()]));

      final res = await r.reportesDenunciados(page: 2, size: 10);

      expect(visto!.method, 'GET');
      expect(visto!.url.path, '/api/admin/reportes-denunciados');
      expect(visto!.url.queryParameters, {'page': '2', 'size': '10'});
      expect(res.items.single.pendientes, 4);
      expect(res.items.single.lugar.nombre, 'Jockey Plaza');
    });

    test('an empty queue is a 200 with no items', () async {
      final res = await repo(200, paginaJson([])).reportesDenunciados();

      expect(res.items, isEmpty);
    });

    test('403 ACCESO_DENEGADO surfaces for a non-admin', () async {
      await expectLater(
        repo(403, error('ACCESO_DENEGADO')).reportesDenunciados(),
        falla(403, 'ACCESO_DENEGADO'),
      );
    });
  });

  group('reporteDenunciado', () {
    test('GETs the detail with motivos', () async {
      final r = repo(200, datosJson(detalleReporteJson()));

      final d = await r.reporteDenunciado(201);

      expect(visto!.url.path, '/api/admin/reportes-denunciados/201');
      expect(d.motivos, hasLength(3));
      expect(d.autor.email, 'carlos.mendez@correo.pe');
    });

    test('404 REPORTE_NO_ENCONTRADO surfaces', () async {
      await expectLater(
        repo(404, error('REPORTE_NO_ENCONTRADO')).reporteDenunciado(1),
        falla(404, 'REPORTE_NO_ENCONTRADO'),
      );
    });
  });

  group('resolver', () {
    test('POSTs {decision} and parses the resolution', () async {
      final r = repo(200, datosJson(resolucionJson()));

      final res = await r.resolver(201, DecisionModeracion.eliminar);

      expect(visto!.method, 'POST');
      expect(visto!.url.path, '/api/admin/reportes-denunciados/201/resolucion');
      expect(cuerpo(), {'decision': 'ELIMINAR'});
      expect(res.estado, EstadoReporteModerado.eliminado);
      expect(res.denunciasResueltas, 4);
    });

    test('sends the trimmed comentario only when there is one', () async {
      final r = repo(200, datosJson(resolucionJson(estado: 'ACTIVO')));

      await r.resolver(
        201,
        DecisionModeracion.mantener,
        comentario: '  Sin infraccion  ',
      );
      expect(cuerpo(), {
        'decision': 'MANTENER',
        'comentario': 'Sin infraccion',
      });

      await r.resolver(201, DecisionModeracion.mantener, comentario: '   ');
      expect(cuerpo(), {'decision': 'MANTENER'});
    });

    test('409 SIN_DENUNCIAS_PENDIENTES surfaces', () async {
      await expectLater(
        repo(
          409,
          error('SIN_DENUNCIAS_PENDIENTES'),
        ).resolver(201, DecisionModeracion.mantener),
        falla(409, 'SIN_DENUNCIAS_PENDIENTES'),
      );
    });
  });

  group('usuarios', () {
    test('sends q, status, orden, page and size', () async {
      final r = repo(200, paginaJson([usuarioJson()]));

      final res = await r.usuarios(
        q: 'luc',
        status: EstadoCuenta.suspendido,
        orden: OrdenUsuarios.karma,
        page: 3,
        size: 5,
      );

      expect(visto!.url.path, '/api/admin/usuarios');
      expect(visto!.url.queryParameters, {
        'q': 'luc',
        'status': 'SUSPENDIDO',
        'orden': 'KARMA',
        'page': '3',
        'size': '5',
      });
      expect(res.items.single.nombre, 'Lucia');
    });

    test('omits q, status and orden when not set', () async {
      await repo(200, paginaJson([])).usuarios();

      expect(visto!.url.queryParameters, {'page': '1', 'size': '20'});
    });

    test('a suspended item exposes the sancion for "faltan N dias"', () async {
      final r = repo(
        200,
        paginaJson([usuarioJson(status: 'SUSPENDIDO', sancion: sancionJson())]),
      );

      final u = (await r.usuarios()).items.single;

      expect(u.sancionVigente!.fechaFin, DateTime.utc(2026, 10, 12, 12));
    });

    test('400 VALIDACION_FALLIDA surfaces', () async {
      await expectLater(
        repo(400, error('VALIDACION_FALLIDA')).usuarios(q: 'a'),
        falla(400, 'VALIDACION_FALLIDA'),
      );
    });
  });

  group('usuario', () {
    test('GETs the detail with the report counters', () async {
      final d = await repo(200, datosJson(detalleUsuarioJson())).usuario(12);

      expect(visto!.url.path, '/api/admin/usuarios/12');
      expect(d.reportesDenunciados, 5);
    });

    test('404 USUARIO_NO_ENCONTRADO surfaces', () async {
      await expectLater(
        repo(404, error('USUARIO_NO_ENCONTRADO')).usuario(1),
        falla(404, 'USUARIO_NO_ENCONTRADO'),
      );
    });
  });

  group('suspender', () {
    test('POSTs {dias, motivo} and returns the 201 sancion', () async {
      final r = repo(201, datosJson(sancionJson()));

      final s = await r.suspender(
        12,
        dias: 7,
        motivo: '  Spam reiterado en reportes ',
      );

      expect(visto!.method, 'POST');
      expect(visto!.url.path, '/api/admin/usuarios/12/suspension');
      expect(cuerpo(), {'dias': 7, 'motivo': 'Spam reiterado en reportes'});
      expect(s.dias, 7);
    });

    for (final (status, code) in [
      (409, 'USUARIO_YA_SUSPENDIDO'),
      (422, 'OPERACION_NO_PERMITIDA'),
      (400, 'VALIDACION_FALLIDA'),
      (404, 'USUARIO_NO_ENCONTRADO'),
    ]) {
      test('$status $code surfaces', () async {
        await expectLater(
          repo(
            status,
            error(code),
          ).suspender(12, dias: 7, motivo: 'Spam reiterado'),
          falla(status, code),
        );
      });
    }
  });

  group('reactivar', () {
    test('POSTs the reactivation without a body', () async {
      final r = repo(200, {'message': 'ok'});

      await r.reactivar(12);

      expect(visto!.method, 'POST');
      expect(visto!.url.path, '/api/admin/usuarios/12/reactivacion');
    });

    test('409 USUARIO_NO_SUSPENDIDO surfaces', () async {
      await expectLater(
        repo(409, error('USUARIO_NO_SUSPENDIDO')).reactivar(12),
        falla(409, 'USUARIO_NO_SUSPENDIDO'),
      );
    });
  });
}
