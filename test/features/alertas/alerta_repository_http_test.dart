import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/session/session_service.dart';
import 'package:crowdradar/features/alertas/data/alerta_repository.dart';
import 'package:crowdradar/features/alertas/data/alerta_repository_http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../fakes/http_falso.dart';

Map<String, dynamic> _alerta(int id, {bool leida = false}) => {
  'id': id,
  'lugarId': 7,
  'lugarNombre': 'Parque Kennedy',
  'nivelAnterior': 'MODERADO',
  'nivelNuevo': 'SATURADO',
  'mensaje': 'Parque Kennedy ahora está Saturado.',
  'leida': leida,
  'fechaHora': '2026-10-05T12:00:00.000Z',
};

Map<String, dynamic> _pagina(List<Map<String, dynamic>> items, int noLeidas) =>
    {
      'message': items.isEmpty ? 'No tienes alertas.' : '',
      'data': {
        'items': items,
        'page': 1,
        'size': 20,
        'total': items.length,
        'totalPaginas': items.isEmpty ? 0 : 2,
        'noLeidas': noLeidas,
      },
    };

void main() {
  late SessionService sesion;
  http.Request? visto;

  AlertaRepositoryHttp repo(int status, Object? body) {
    visto = null;
    return AlertaRepositoryHttp(
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

  group('listar', () {
    test('GETs the page and keeps the unread counter', () async {
      final r = repo(200, _pagina([_alerta(1), _alerta(2, leida: true)], 1));

      final res = await r.listar(page: 2);

      expect(visto!.url.path, '/api/alertas');
      expect(visto!.url.queryParameters['page'], '2');
      expect(res.noLeidas, 1);
      expect(res.pagina.items.map((a) => a.id), [1, 2]);
      expect(res.pagina.items.first.nivelNuevo, NivelSaturacion.saturado);
      expect(res.pagina.items.last.leida, isTrue);
      expect(res.pagina.hayMas, isTrue);
    });

    test('empty list carries the message and zero unread', () async {
      final res = await repo(200, _pagina([], 0)).listar();

      expect(res.pagina.items, isEmpty);
      expect(res.mensaje, 'No tienes alertas.');
      expect(res.noLeidas, 0);
    });

    test('401 and offline surface as ApiException', () async {
      await expectLater(
        repo(401, {'code': 'NO_AUTENTICADO', 'message': 'x'}).listar(),
        falla(401, 'NO_AUTENTICADO'),
      );
      final sinRed = AlertaRepositoryHttp(
        apiClientPrueba((_) async => throw http.ClientException('x'), sesion),
      );
      await expectLater(
        sinRed.listar(),
        throwsA(
          isA<ApiException>().having((e) => e.esSinConexion, 'off', true),
        ),
      );
    });
  });

  group('marcarLeida', () {
    test('PATCHes /api/alertas/:id/leida', () async {
      final r = repo(200, {'message': '', 'data': _alerta(3, leida: true)});

      await r.marcarLeida(3);

      expect(visto!.method, 'PATCH');
      expect(visto!.url.path, '/api/alertas/3/leida');
    });

    test('404 is ALERTA_NO_ENCONTRADA', () async {
      await expectLater(
        repo(404, {
          'code': 'ALERTA_NO_ENCONTRADA',
          'message': 'x',
        }).marcarLeida(3),
        falla(404, 'ALERTA_NO_ENCONTRADA'),
      );
    });
  });

  group('dispositivos', () {
    test('registrar POSTs token and wire platform (201 and 200)', () async {
      for (final status in [201, 200]) {
        final r = repo(status, {'message': '', 'data': <String, dynamic>{}});
        await r.registrarDispositivo('tok-1', PlataformaPush.android);
        expect(visto!.method, 'POST');
        expect(visto!.url.path, '/api/dispositivos');
        expect(visto!.body, '{"token":"tok-1","plataforma":"ANDROID"}');
      }
      await repo(201, {
        'message': '',
        'data': <String, dynamic>{},
      }).registrarDispositivo('t', PlataformaPush.ios);
      expect(visto!.body, '{"token":"t","plataforma":"IOS"}');
    });

    test('registrar 400 surfaces the validation error', () async {
      await expectLater(
        repo(400, {
          'code': 'VALIDACION_FALLIDA',
          'message': 'x',
        }).registrarDispositivo('t', PlataformaPush.ios),
        falla(400, 'VALIDACION_FALLIDA'),
      );
    });

    test(
      'eliminar DELETEs the url-encoded token and accepts the 204',
      () async {
        final r = repo(204, null);

        await r.eliminarDispositivo('a/b c');

        expect(visto!.method, 'DELETE');
        expect(visto!.url.path, '/api/dispositivos/a%2Fb%20c');
      },
    );
  });
}
