import 'dart:async';

import 'package:crowdradar/core/network/api_client.dart';
import 'package:crowdradar/core/network/interceptores/interceptores_sesion.dart';
import 'package:crowdradar/core/config/entorno.dart';
import 'package:crowdradar/core/session/motivo_cierre.dart';
import 'package:crowdradar/core/session/session_service.dart';
import 'package:crowdradar/core/storage/memoria_token_storage.dart';
import 'package:crowdradar/core/session/sesion_cubit.dart';
import 'package:crowdradar/core/session/sesion_state.dart';
import 'package:crowdradar/core/session/usuario_sesion.dart';
import 'package:crowdradar/core/storage/secure_token_storage.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../fakes/jwt_falso.dart';
import '../../fakes/registro_falso.dart';

void main() {
  final ahora = DateTime.utc(2026, 10, 5, 12);
  late MemoriaTokenStorage storage;
  late SessionService sesion;
  late String tokenVigente;

  setUp(() {
    tokenVigente = jwtFalso(exp: ahora.add(const Duration(hours: 2)));
    storage = MemoriaTokenStorage();
    sesion = SessionService.instance..reiniciar();
    sesion.configurar(storage, reloj: () => ahora);
  });

  tearDown(() => sesion.reiniciar());

  group('restaurar', () {
    test('S4.1 stored valid session becomes active', () async {
      await storage.guardar(tokenVigente, usuarioPrueba);

      await sesion.restaurar();

      expect(sesion.token, tokenVigente);
      expect(sesion.usuario, usuarioPrueba);
    });

    test('S4.2 user without token clears storage', () async {
      await storage.guardar(tokenVigente, usuarioPrueba);
      storage.token = null;

      await sesion.restaurar();

      expect(sesion.token, isNull);
      expect(await storage.leerUsuario(), isNull);
    });

    test('S4.2 token without user clears storage', () async {
      await storage.guardar(tokenVigente, usuarioPrueba);
      storage.usuario = null;

      await sesion.restaurar();

      expect(sesion.usuario, isNull);
      expect(await storage.leerToken(), isNull);
    });

    test('S4.3 expired token clears storage and leaves no session', () async {
      final vencido = jwtFalso(exp: ahora.subtract(const Duration(minutes: 1)));
      await storage.guardar(vencido, usuarioPrueba);

      await sesion.restaurar();

      expect(sesion.token, isNull);
      expect(await storage.leerToken(), isNull);
    });

    test('startup: nothing stored means no wipe round-trip', () async {
      final contador = _StorageContador();
      sesion.configurar(contador, reloj: () => ahora);

      await sesion.restaurar();

      expect(sesion.token, isNull);
      expect(contador.borrados, 0);
    });

    test('startup: token and user are read concurrently', () async {
      final contador = _StorageContador()
        ..token = tokenVigente
        ..usuario = usuarioPrueba
        ..retenerToken = Completer<void>();
      sesion.configurar(contador, reloj: () => ahora);

      final restauracion = sesion.restaurar();
      await Future<void>.delayed(Duration.zero);
      expect(contador.lecturasUsuario, 1);

      contador.retenerToken!.complete();
      await restauracion;
      expect(sesion.token, tokenVigente);
      expect(sesion.usuario, usuarioPrueba);
    });

    test('S4.5 storage failure means no session and no crash', () async {
      sesion.configurar(StorageQueFalla(), reloj: () => ahora);

      await sesion.restaurar();

      expect(sesion.token, isNull);
      expect(sesion.usuario, isNull);
    });
  });

  group('lifecycle', () {
    test('S4.4 iniciar persists and emits SesionIniciada', () async {
      final eventos = <EventoSesion>[];
      sesion.eventos.listen(eventos.add);

      await sesion.iniciar(tokenVigente, usuarioPrueba);
      await Future<void>.delayed(Duration.zero);

      expect(await storage.leerToken(), tokenVigente);
      expect(await storage.leerUsuario(), usuarioPrueba);
      expect(eventos.single, isA<SesionIniciada>());
      expect((eventos.single as SesionIniciada).usuario, usuarioPrueba);
    });

    test(
      'S4.4 cerrar clears storage and emits SesionCerrada(motivo)',
      () async {
        await sesion.iniciar(tokenVigente, usuarioPrueba);
        final eventos = <EventoSesion>[];
        sesion.eventos.listen(eventos.add);

        await sesion.cerrar(MotivoCierre.usuario);
        await Future<void>.delayed(Duration.zero);

        expect(sesion.token, isNull);
        expect(await storage.leerToken(), isNull);
        expect((eventos.single as SesionCerrada).motivo, MotivoCierre.usuario);
      },
    );

    test('S4.4 expirar behaves like cerrar and only fires once', () async {
      await sesion.iniciar(tokenVigente, usuarioPrueba);
      final eventos = <EventoSesion>[];
      sesion.eventos.listen(eventos.add);

      await sesion.expirar(MotivoCierre.sesionExpirada);
      await sesion.expirar(MotivoCierre.sesionExpirada);
      await Future<void>.delayed(Duration.zero);

      expect(eventos, hasLength(1));
      expect(
        (eventos.single as SesionCerrada).motivo,
        MotivoCierre.sesionExpirada,
      );
    });

    test('actualizarUsuario replaces the user and persists it', () async {
      await sesion.iniciar(tokenVigente, usuarioPrueba);

      await sesion.actualizarUsuario(adminPrueba);

      expect(sesion.usuario, adminPrueba);
      expect(await storage.leerUsuario(), adminPrueba);
      expect(sesion.token, tokenVigente);
    });
  });

  group('restaurar (review fixes)', () {
    test('R3-008 restored ADMIN session yields esAdmin', () async {
      await storage.guardar(tokenVigente, adminPrueba);

      await sesion.restaurar();

      expect(
        SesionCubit(sesion).state,
        const SesionAutenticada(usuario: adminPrueba, esAdmin: true),
      );
    });

    test('R3-007 slow storage times out and means no session', () async {
      final registro = RegistroFalso();
      final lento = StorageLento();
      await lento.guardar(tokenVigente, usuarioPrueba);
      sesion.configurar(
        lento,
        reloj: () => ahora,
        registro: registro,
        timeoutRestaurar: const Duration(milliseconds: 20),
      );

      await sesion.restaurar();

      expect(sesion.token, isNull);
      expect(registro.registros, hasLength(1));
    });

    test(
      'R3-F01 a late storage result after the timeout is discarded',
      () => fakeAsync((reloj) {
        final lento = StorageLento();
        lento.guardar(tokenVigente, usuarioPrueba);
        sesion.configurar(
          lento,
          reloj: () => ahora,
          registro: RegistroFalso(),
          timeoutRestaurar: const Duration(milliseconds: 20),
        );
        final eventos = <EventoSesion>[];
        final sub = sesion.eventos.listen(eventos.add);

        var restaurada = false;
        sesion.restaurar().then((_) => restaurada = true);
        reloj.elapse(const Duration(milliseconds: 20));
        expect(restaurada, isTrue);
        // Well past the slow read (300 ms): its late result must be dropped.
        reloj.elapse(const Duration(milliseconds: 500));
        sub.cancel();
        reloj.flushMicrotasks();

        expect(sesion.token, isNull);
        expect(sesion.usuario, isNull);
        expect(eventos, isEmpty);
      }),
    );

    test('R4-004 storage failure on restore is reported', () async {
      final registro = RegistroFalso();
      sesion.configurar(
        StorageQueFalla(),
        reloj: () => ahora,
        registro: registro,
      );

      await sesion.restaurar();

      expect(registro.registros.single.contexto, contains('restaurar'));
    });
  });

  group('failing storage (review fixes)', () {
    test(
      'R3-002 cerrar clears memory and emits even if borrar throws',
      () async {
        await sesion.iniciar(tokenVigente, usuarioPrueba);
        final registro = RegistroFalso();
        sesion.configurar(
          StorageQueFallaAlEscribir(),
          reloj: () => ahora,
          registro: registro,
        );
        final eventos = <EventoSesion>[];
        sesion.eventos.listen(eventos.add);

        await sesion.cerrar(MotivoCierre.usuario);
        await Future<void>.delayed(Duration.zero);

        expect(sesion.token, isNull);
        expect(sesion.usuario, isNull);
        expect(eventos.single, isA<SesionCerrada>());
        expect(registro.registros, hasLength(1));
      },
    );

    test('R3-002 expirar emits even if borrar throws', () async {
      await sesion.iniciar(tokenVigente, usuarioPrueba);
      sesion.configurar(StorageQueFallaAlEscribir(), reloj: () => ahora);
      final eventos = <EventoSesion>[];
      sesion.eventos.listen(eventos.add);

      await sesion.expirar(MotivoCierre.sesionExpirada);
      await Future<void>.delayed(Duration.zero);

      expect(sesion.token, isNull);
      expect(eventos.single, isA<SesionCerrada>());
    });

    test(
      'R3-003 iniciar persists first: on failure nothing is mutated',
      () async {
        sesion.configurar(StorageQueFallaAlEscribir(), reloj: () => ahora);
        final eventos = <EventoSesion>[];
        sesion.eventos.listen(eventos.add);

        await expectLater(
          sesion.iniciar(tokenVigente, usuarioPrueba),
          throwsA(isA<ErrorAlmacenamientoSesion>()),
        );
        await Future<void>.delayed(Duration.zero);

        expect(sesion.token, isNull);
        expect(sesion.usuario, isNull);
        expect(eventos, isEmpty);
      },
    );

    test('R3-008 SesionCubit sequence on failing storage', () async {
      await sesion.iniciar(tokenVigente, usuarioPrueba);
      final cubit = SesionCubit(sesion);
      final estados = <SesionState>[];
      cubit.stream.listen(estados.add);
      sesion.configurar(StorageQueFallaAlEscribir(), reloj: () => ahora);

      await cubit.cerrarSesion();
      await expectLater(
        sesion.iniciar(tokenVigente, usuarioPrueba),
        throwsA(isA<ErrorAlmacenamientoSesion>()),
      );
      await Future<void>.delayed(Duration.zero);

      expect(estados, [
        const SesionNoAutenticada(motivo: MotivoCierre.usuario),
      ]);
      await cubit.close();
    });
  });

  group('wiring', () {
    test(
      'S3.3 401 through ApiClient expires the real SessionService',
      () async {
        await sesion.iniciar(tokenVigente, usuarioPrueba);
        final eventos = <EventoSesion>[];
        sesion.eventos.listen(eventos.add);
        String? authVisto;
        final api = ApiClient(
          MockClient((r) async {
            authVisto = r.headers['Authorization'];
            return http.Response('{"message":"x"}', 401);
          }),
          const Entorno(),
          interceptores: interceptoresDeSesion(sesion),
        );

        await expectLater(
          api.get<Object?>('/api/users/profile', parser: (d) => d),
          throwsA(anything),
        );
        await Future<void>.delayed(Duration.zero);

        expect(authVisto, 'Bearer $tokenVigente');
        expect(sesion.token, isNull);
        expect(eventos.whereType<SesionCerrada>(), hasLength(1));
      },
    );

    test('R3-008 concurrent 401s emit a single SesionCerrada', () async {
      await sesion.iniciar(tokenVigente, usuarioPrueba);
      final eventos = <EventoSesion>[];
      sesion.eventos.listen(eventos.add);
      final api = ApiClient(
        MockClient((r) async => http.Response('{"message":"x"}', 401)),
        const Entorno(),
        interceptores: interceptoresDeSesion(sesion),
      );

      await Future.wait([
        for (var i = 0; i < 3; i++)
          api
              .get<Object?>('/api/users/profile', parser: (d) => d)
              .then((_) => null, onError: (_) => null),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(eventos.whereType<SesionCerrada>(), hasLength(1));
    });
  });

  group('SecureTokenStorage', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('round-trips token and user, then borrar clears both', () async {
      final s = SecureTokenStorage(const FlutterSecureStorage());

      await s.guardar('t', usuarioPrueba);
      expect(await s.leerToken(), 't');
      expect(await s.leerUsuario(), usuarioPrueba);

      await s.borrar();
      expect(await s.leerToken(), isNull);
      expect(await s.leerUsuario(), isNull);
    });

    test('corrupt user JSON reads as null', () async {
      FlutterSecureStorage.setMockInitialValues({'crowdradar.usuario': '{no'});
      final s = SecureTokenStorage(const FlutterSecureStorage());

      expect(await s.leerUsuario(), isNull);
    });
  });
}

/// Counts wipes and user reads; can hold the token read open.
class _StorageContador extends MemoriaTokenStorage {
  int borrados = 0;
  int lecturasUsuario = 0;
  Completer<void>? retenerToken;

  @override
  Future<String?> leerToken() async {
    await retenerToken?.future;
    return token;
  }

  @override
  Future<UsuarioSesion?> leerUsuario() async {
    lecturasUsuario++;
    return usuario;
  }

  @override
  Future<void> borrar() async {
    borrados++;
    await super.borrar();
  }
}
