import 'package:crowdradar/core/models/validacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/session/session_service.dart';
import 'package:crowdradar/features/validacion/data/validacion_repository_http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../fakes/http_falso.dart';
import 'json_validacion.dart';

void main() {
  late SessionService sesion;
  http.Request? visto;

  ValidacionRepositoryHttp repo(int status, Object? body) {
    visto = null;
    return ValidacionRepositoryHttp(
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

  group('pendientes', () {
    test('sends lat/lng/radioKm/horas/page/size and parses the page', () async {
      final r = repo(200, paginaJson([pendienteJson()]));

      final res = await r.pendientes(lat: -12.1, lng: -77.0, radioKm: 2);

      expect(visto!.method, 'GET');
      expect(visto!.url.path, '/api/validaciones/pendientes');
      expect(visto!.url.queryParameters, {
        'lat': '-12.1',
        'lng': '-77.0',
        'radioKm': '2.0',
        'horas': '3',
        'page': '1',
        'size': '20',
      });
      expect(res.items.single.lugar.nombre, 'Parque Kennedy');
    });

    test('an empty 200 is an empty page, not an error', () async {
      final res = await repo(200, paginaJson([])).pendientes(lat: 0, lng: 0);

      expect(res.items, isEmpty);
    });

    test('400 VALIDACION_FALLIDA surfaces', () async {
      await expectLater(
        repo(400, {
          'message': 'x',
          'code': 'VALIDACION_FALLIDA',
        }).pendientes(lat: 0, lng: 0),
        falla(400, 'VALIDACION_FALLIDA'),
      );
    });
  });

  group('obtenerReporte', () {
    test('GETs /api/reportes/:id and parses the detail', () async {
      final r = repo(200, {'message': 'ok', 'data': detalleJson()});

      final d = await r.obtenerReporte(31);

      expect(visto!.url.path, '/api/reportes/31');
      expect(d.estadoValidacion, EstadoValidacion.validado);
    });

    test('404 REPORTE_NO_ENCONTRADO surfaces', () async {
      await expectLater(
        repo(404, {
          'message': 'x',
          'code': 'REPORTE_NO_ENCONTRADO',
        }).obtenerReporte(1),
        falla(404, 'REPORTE_NO_ENCONTRADO'),
      );
    });
  });

  test('confiabilidad GETs the block only', () async {
    final r = repo(200, {'message': 'ok', 'data': confiabilidadJson()});

    final c = await r.confiabilidad(31);

    expect(visto!.url.path, '/api/reportes/31/confiabilidad');
    expect(c.nivel, NivelConfiabilidad.alta);
  });

  group('validar', () {
    test('POSTs tipoAccion and returns the karma outcome', () async {
      final r = repo(201, votoCreadoJson());

      final v = await r.validar(31, TipoAccionValidacion.confirmar);

      expect(visto!.method, 'POST');
      expect(visto!.url.path, '/api/reportes/31/validaciones');
      expect(visto!.body, '{"tipoAccion":"CONFIRMAR"}');
      expect(v.puntosGanados, 2);
      expect(v.totalKarma, 112);
    });

    test('RECHAZAR is sent as the wire value', () async {
      final r = repo(201, votoCreadoJson());

      await r.validar(31, TipoAccionValidacion.rechazar);

      expect(visto!.body, '{"tipoAccion":"RECHAZAR"}');
    });

    for (final (status, code) in [
      (404, 'REPORTE_NO_ENCONTRADO'),
      (422, 'AUTOVALIDACION_NO_PERMITIDA'),
      (409, 'VALIDACION_DUPLICADA'),
    ]) {
      test('$status $code surfaces', () async {
        await expectLater(
          repo(status, {
            'message': 'x',
            'code': code,
          }).validar(31, TipoAccionValidacion.confirmar),
          falla(status, code),
        );
      });
    }
  });

  group('estadoMisReportes', () {
    test('GETs the paginated list', () async {
      final r = repo(200, paginaJson([estadoMioJson()]));

      final res = await r.estadoMisReportes(page: 2, size: 10);

      expect(visto!.url.path, '/api/reportes/mios/validacion');
      expect(visto!.url.queryParameters, {'page': '2', 'size': '10'});
      expect(res.items.single.reporteId, 5);
    });
  });

  group('denunciar', () {
    test('POSTs the wire motivo without detalle', () async {
      final r = repo(201, {'message': 'ok', 'data': {}});

      await r.denunciar(31, MotivoDenuncia.informacionFalsa);

      expect(visto!.url.path, '/api/reportes/31/denuncias');
      expect(visto!.body, '{"motivo":"INFORMACION_FALSA"}');
    });

    test('OTRO sends the trimmed detalle', () async {
      final r = repo(201, {'message': 'ok', 'data': {}});

      await r.denunciar(31, MotivoDenuncia.otro, detalle: '  mentira  ');

      expect(visto!.body, '{"motivo":"OTRO","detalle":"mentira"}');
    });

    for (final (status, code) in [
      (422, 'AUTODENUNCIA_NO_PERMITIDA'),
      (409, 'DENUNCIA_DUPLICADA'),
    ]) {
      test('$status $code surfaces', () async {
        await expectLater(
          repo(status, {
            'message': 'x',
            'code': code,
          }).denunciar(31, MotivoDenuncia.spam),
          falla(status, code),
        );
      });
    }
  });
}
