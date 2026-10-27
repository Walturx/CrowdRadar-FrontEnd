import 'package:crowdradar/core/models/categoria_lugar.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/session/session_service.dart';
import 'package:crowdradar/features/favoritos/data/favorito_repository_http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../fakes/http_falso.dart';

Map<String, dynamic> _favorito(int id, {bool alertas = true}) => {
  'lugarId': id,
  'nombre': 'Parque $id',
  'categoria': 'PARQUE',
  'saturacion': 'MODERADO',
  'alertasActivadas': alertas,
};

void main() {
  late SessionService sesion;
  http.Request? visto;

  FavoritoRepositoryHttp repo(int status, Object? body) {
    visto = null;
    return FavoritoRepositoryHttp(
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
    test('GETs /api/favoritos and maps the items', () async {
      final r = repo(200, {
        'message': '',
        'data': {
          'items': [_favorito(7), _favorito(8, alertas: false)],
        },
      });

      final res = await r.listar();

      expect(visto!.method, 'GET');
      expect(visto!.url.path, '/api/favoritos');
      expect(res.items.map((f) => f.lugarId), [7, 8]);
      expect(res.items.first.categoria, CategoriaLugar.parque);
      expect(res.items.first.saturacion, NivelSaturacion.moderado);
      expect(res.items.last.alertasActivadas, isFalse);
    });

    test('an empty list carries the server message', () async {
      final r = repo(200, {
        'message': 'No tienes lugares favoritos registrados.',
        'data': {'items': []},
      });

      final res = await r.listar();

      expect(res.estaVacia, isTrue);
      expect(res.mensaje, 'No tienes lugares favoritos registrados.');
    });

    test('401 and offline surface as ApiException', () async {
      await expectLater(
        repo(401, {'code': 'NO_AUTENTICADO', 'message': 'x'}).listar(),
        falla(401, 'NO_AUTENTICADO'),
      );
      final sinRed = FavoritoRepositoryHttp(
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

  group('agregar', () {
    test('POSTs the lugarId', () async {
      final r = repo(201, {
        'message': 'Añadido a favoritos',
        'data': _favorito(7),
      });

      await r.agregar(7);

      expect(visto!.method, 'POST');
      expect(visto!.url.path, '/api/favoritos');
      expect(visto!.body, '{"lugarId":7}');
    });

    test('409 keeps its FAVORITO_DUPLICADO code and HU message', () async {
      final r = repo(409, {
        'code': 'FAVORITO_DUPLICADO',
        'message': 'Este lugar ya pertenece a tus favoritos.',
      });

      await expectLater(
        r.agregar(7),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'FAVORITO_DUPLICADO')
              .having(
                (e) => e.message,
                'message',
                'Este lugar ya pertenece a tus favoritos.',
              ),
        ),
      );
    });
  });

  group('eliminar', () {
    test('DELETEs /api/favoritos/:id and accepts the 204', () async {
      final r = repo(204, null);

      await r.eliminar(7);

      expect(visto!.method, 'DELETE');
      expect(visto!.url.path, '/api/favoritos/7');
    });

    test('404 is FAVORITO_NO_ENCONTRADO', () async {
      await expectLater(
        repo(404, {
          'code': 'FAVORITO_NO_ENCONTRADO',
          'message': 'x',
        }).eliminar(7),
        falla(404, 'FAVORITO_NO_ENCONTRADO'),
      );
    });
  });

  group('configurarAlertas', () {
    test('PATCHes the preference (false and true)', () async {
      final r = repo(200, {
        'message': '',
        'data': _favorito(7, alertas: false),
      });

      await r.configurarAlertas(7, activadas: false);
      expect(visto!.method, 'PATCH');
      expect(visto!.url.path, '/api/favoritos/7/alertas');
      expect(visto!.body, '{"alertasActivadas":false}');

      await r.configurarAlertas(7, activadas: true);
      expect(visto!.body, '{"alertasActivadas":true}');
    });

    test('404 when the place is not a favorite', () async {
      await expectLater(
        repo(404, {
          'code': 'FAVORITO_NO_ENCONTRADO',
          'message': 'x',
        }).configurarAlertas(7, activadas: true),
        falla(404, 'FAVORITO_NO_ENCONTRADO'),
      );
    });
  });
}
