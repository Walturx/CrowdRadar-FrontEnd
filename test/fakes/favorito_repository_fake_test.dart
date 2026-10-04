import 'package:crowdradar/app/fakes/favorito_repository_fake.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/session/session_service.dart';
import 'package:crowdradar/core/session/usuario_sesion.dart';
import 'package:flutter_test/flutter_test.dart';

Matcher _falla(int status, String code) => throwsA(
  isA<ApiException>()
      .having((e) => e.status, 'status', status)
      .having((e) => e.code, 'code', code),
);

void main() {
  test('starts empty with the HU 8.2 message', () async {
    final r = await FavoritoRepositoryFake().listar();

    expect(r.estaVacia, isTrue);
    expect(r.mensaje, 'No tienes lugares favoritos registrados.');
  });

  test('agregar creates an active favorite with the place data', () async {
    final repo = FavoritoRepositoryFake();

    await repo.agregar(2);
    await repo.agregar(1);
    final items = (await repo.listar()).items;

    expect(items.map((f) => f.lugarId), [1, 2], reason: 'newest first');
    expect(items.last.nombre, 'Mercado de Surquillo');
    expect(items.last.saturacion, NivelSaturacion.saturado);
    expect(items.first.saturacion, NivelSaturacion.tranquilo);
    expect(items.every((f) => f.alertasActivadas), isTrue);
  });

  test('409 duplicate uses the HU message; unknown place is a 404', () async {
    final repo = FavoritoRepositoryFake();
    await repo.agregar(1);

    await expectLater(
      repo.agregar(1),
      throwsA(
        isA<ApiException>()
            .having((e) => e.status, 'status', 409)
            .having((e) => e.code, 'code', 'FAVORITO_DUPLICADO')
            .having(
              (e) => e.message,
              'message',
              'Este lugar ya pertenece a tus favoritos.',
            ),
      ),
    );
    await expectLater(repo.agregar(999), _falla(404, 'LUGAR_NO_ENCONTRADO'));
  });

  test('configurarAlertas toggles and 404 when not a favorite', () async {
    final repo = FavoritoRepositoryFake();
    await repo.agregar(1);

    await repo.configurarAlertas(1, activadas: false);
    expect((await repo.listar()).items.single.alertasActivadas, isFalse);
    await repo.configurarAlertas(1, activadas: true);
    expect((await repo.listar()).items.single.alertasActivadas, isTrue);
    await expectLater(
      repo.configurarAlertas(2, activadas: true),
      _falla(404, 'FAVORITO_NO_ENCONTRADO'),
    );
  });

  test('eliminar removes it and a second delete is a 404', () async {
    final repo = FavoritoRepositoryFake();
    await repo.agregar(1);

    await repo.eliminar(1);

    expect((await repo.listar()).estaVacia, isTrue);
    await expectLater(repo.eliminar(1), _falla(404, 'FAVORITO_NO_ENCONTRADO'));
  });

  test('with a session service, every call needs a signed-in user', () async {
    final sesion = SessionService.instance..reiniciar();
    final repo = FavoritoRepositoryFake(sesion: sesion);

    await expectLater(repo.listar(), _falla(401, 'NO_AUTENTICADO'));
    await expectLater(repo.agregar(1), _falla(401, 'NO_AUTENTICADO'));

    await sesion.iniciar('token', const UsuarioSesion(id: 1));
    await repo.agregar(1);
    expect((await repo.listar()).items, hasLength(1));
    sesion.reiniciar();
  });
}
