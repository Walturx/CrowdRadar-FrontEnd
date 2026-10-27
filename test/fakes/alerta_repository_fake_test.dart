import 'package:crowdradar/app/fakes/alerta_repository_fake.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/session/session_service.dart';
import 'package:crowdradar/core/session/usuario_sesion.dart';
import 'package:crowdradar/features/alertas/data/alerta_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Matcher _falla(int status, String code) => throwsA(
  isA<ApiException>()
      .having((e) => e.status, 'status', status)
      .having((e) => e.code, 'code', code),
);

void main() {
  test(
    'seeds a deterministic unread alert and a read one, newest first',
    () async {
      final res = await AlertaRepositoryFake().listar();

      expect(res.noLeidas, 1);
      expect(res.pagina.items, hasLength(2));
      final primera = res.pagina.items.first;
      expect(primera.leida, isFalse);
      expect(primera.lugarId, 1);
      expect(primera.nivelAnterior, NivelSaturacion.moderado);
      expect(primera.nivelNuevo, NivelSaturacion.saturado);
      expect(res.pagina.items.last.leida, isTrue);
    },
  );

  test('marcarLeida lowers the unread counter and is idempotent', () async {
    final repo = AlertaRepositoryFake();
    final id = (await repo.listar()).pagina.items.first.id;

    await repo.marcarLeida(id);
    await repo.marcarLeida(id);

    final res = await repo.listar();
    expect(res.noLeidas, 0);
    expect(res.pagina.items.every((a) => a.leida), isTrue);
    await expectLater(
      repo.marcarLeida(999),
      _falla(404, 'ALERTA_NO_ENCONTRADA'),
    );
  });

  test(
    'emitir adds an unread alert on top; empty store has the message',
    () async {
      final repo = AlertaRepositoryFake(sembrar: false);
      final vacio = await repo.listar();
      expect(vacio.pagina.items, isEmpty);
      expect(vacio.mensaje, 'No tienes alertas.');
      expect(vacio.noLeidas, 0);

      repo.emitir(3, NivelSaturacion.tranquilo, NivelSaturacion.moderado);
      final res = await repo.listar();

      expect(res.noLeidas, 1);
      expect(res.pagina.items.single.lugarNombre, 'Playa Costa Verde');
      expect(
        res.pagina.items.single.mensaje,
        'Playa Costa Verde ahora está Moderado. La saturación cambió de '
        'Tranquilo a Moderado.',
      );
    },
  );

  test('listar pages the alerts', () async {
    final repo = AlertaRepositoryFake();

    final p1 = await repo.listar(page: 1, size: 1);
    final p2 = await repo.listar(page: 2, size: 1);

    expect(p1.pagina.items.single.id, isNot(p2.pagina.items.single.id));
    expect(p1.pagina.hayMas, isTrue);
    expect(p2.pagina.hayMas, isFalse);
  });

  test('devices: register upserts by token, delete is idempotent', () async {
    final repo = AlertaRepositoryFake();

    await repo.registrarDispositivo('tok', PlataformaPush.android);
    await repo.registrarDispositivo('tok', PlataformaPush.android);
    expect(repo.dispositivos, ['tok']);
    await repo.eliminarDispositivo('tok');
    await repo.eliminarDispositivo('tok');
    expect(repo.dispositivos, isEmpty);
  });

  test('device token must have 1-255 chars', () async {
    final repo = AlertaRepositoryFake();

    await expectLater(
      repo.registrarDispositivo('', PlataformaPush.ios),
      _falla(400, 'VALIDACION_FALLIDA'),
    );
    await expectLater(
      repo.registrarDispositivo('x' * 256, PlataformaPush.ios),
      _falla(400, 'VALIDACION_FALLIDA'),
    );
    await repo.registrarDispositivo('x' * 255, PlataformaPush.ios);
    expect(repo.dispositivos, hasLength(1));
  });

  test('with a session service, calls need a signed-in user', () async {
    final sesion = SessionService.instance..reiniciar();
    final repo = AlertaRepositoryFake(sesion: sesion);

    await expectLater(repo.listar(), _falla(401, 'NO_AUTENTICADO'));

    await sesion.iniciar('token', const UsuarioSesion(id: 1));
    expect((await repo.listar()).pagina.items, isNotEmpty);
    sesion.reiniciar();
  });
}
