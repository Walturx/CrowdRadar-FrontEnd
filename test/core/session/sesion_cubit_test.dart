import 'package:bloc_test/bloc_test.dart';
import 'package:crowdradar/core/session/motivo_cierre.dart';
import 'package:crowdradar/core/session/sesion_cubit.dart';
import 'package:crowdradar/core/session/sesion_state.dart';
import 'package:crowdradar/core/session/session_service.dart';
import 'package:crowdradar/core/storage/memoria_token_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/jwt_falso.dart';

void main() {
  final ahora = DateTime.utc(2026, 10, 5, 12);
  late SessionService sesion;
  late String token;

  setUp(() {
    token = jwtFalso(exp: ahora.add(const Duration(hours: 2)));
    sesion = SessionService.instance..reiniciar();
    sesion.configurar(MemoriaTokenStorage(), reloj: () => ahora);
  });

  tearDown(() => sesion.reiniciar());

  test('initial state is unauthenticated without a session', () {
    expect(SesionCubit(sesion).state, const SesionNoAutenticada());
  });

  test('initial state reflects a restored session (user)', () async {
    await sesion.iniciar(token, usuarioPrueba);

    expect(SesionCubit(sesion).state,
        const SesionAutenticada(usuario: usuarioPrueba, esAdmin: false));
  });

  test('initial state flags admins', () async {
    await sesion.iniciar(token, adminPrueba);

    final estado = SesionCubit(sesion).state as SesionAutenticada;
    expect(estado.esAdmin, isTrue);
  });

  blocTest<SesionCubit, SesionState>(
    'SesionIniciada event emits SesionAutenticada',
    build: () => SesionCubit(sesion),
    act: (_) => sesion.iniciar(token, usuarioPrueba),
    expect: () => [
      const SesionAutenticada(usuario: usuarioPrueba, esAdmin: false),
    ],
  );

  blocTest<SesionCubit, SesionState>(
    'S5.4 expiry event emits SesionNoAutenticada with motivo',
    build: () => SesionCubit(sesion),
    act: (_) async {
      await sesion.iniciar(token, usuarioPrueba);
      await sesion.expirar(MotivoCierre.sesionExpirada);
    },
    skip: 1,
    expect: () => [
      const SesionNoAutenticada(motivo: MotivoCierre.sesionExpirada),
    ],
  );

  blocTest<SesionCubit, SesionState>(
    'cerrarSesion closes with motivo usuario',
    build: () => SesionCubit(sesion),
    act: (c) async {
      await sesion.iniciar(token, usuarioPrueba);
      await c.cerrarSesion();
    },
    skip: 1,
    expect: () => [
      const SesionNoAutenticada(motivo: MotivoCierre.usuario),
    ],
  );

  test('R4-103 cerrarSesion with throwing storage still ends closed, no throw',
      () async {
    await sesion.iniciar(token, usuarioPrueba);
    final cubit = SesionCubit(sesion);
    sesion.configurar(StorageQueFallaAlEscribir(), reloj: () => ahora);

    await cubit.cerrarSesion();
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state,
        const SesionNoAutenticada(motivo: MotivoCierre.usuario));
    await cubit.close();
  });
  group('antesDeCerrar hook', () {
    test('runs while the session is still valid, then closes', () async {
      await sesion.iniciar(token, usuarioPrueba);
      String? tokenVisto;
      final cubit = SesionCubit(
        sesion,
        antesDeCerrar: () async => tokenVisto = sesion.token,
      );

      await cubit.cerrarSesion();
      await Future<void>.delayed(Duration.zero);

      expect(tokenVisto, token);
      expect(sesion.token, isNull);
      expect(cubit.state, const SesionNoAutenticada(motivo: MotivoCierre.usuario));
      await cubit.close();
    });

    test('a failing hook never keeps the user signed in', () async {
      await sesion.iniciar(token, usuarioPrueba);
      final cubit = SesionCubit(
        sesion,
        antesDeCerrar: () async => throw Exception('sin red'),
      );

      await cubit.cerrarSesion();
      await Future<void>.delayed(Duration.zero);

      expect(sesion.token, isNull);
      expect(cubit.state, const SesionNoAutenticada(motivo: MotivoCierre.usuario));
      await cubit.close();
    });
  });
}
