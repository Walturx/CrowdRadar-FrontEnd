import 'package:bloc_test/bloc_test.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/features/auth/data/auth_repository.dart';
import 'package:crowdradar/features/auth/recuperar/recuperar_cubit.dart';
import 'package:crowdradar/features/auth/recuperar/recuperar_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../../helpers/errores_comunes.dart';

class _AuthRepoMock extends Mock implements AuthRepository {}

void main() {
  late _AuthRepoMock repo;
  setUp(() => repo = _AuthRepoMock());

  blocTest<RecuperarCubit, RecuperarState>(
    'HU 2.1 c2 success -> Enviando, Enviado with the neutral message',
    build: () {
      when(
        () => repo.solicitarRecuperacion('ana@test.com'),
      ).thenAnswer((_) async {});
      return RecuperarCubit(repo);
    },
    act: (c) => c.enviar(' ana@test.com '),
    expect: () => [
      const RecuperarEnviando(),
      const RecuperarEnviado(RecuperarCubit.mensajeNeutral),
    ],
    verify: (_) =>
        verify(() => repo.solicitarRecuperacion('ana@test.com')).called(1),
  );

  test(
    'the neutral message promises a link only if the email is registered',
    () {
      expect(
        RecuperarCubit.mensajeNeutral,
        startsWith('Si el correo está registrado'),
      );
    },
  );

  for (final email in ['', '   ', 'sin-arroba', 'a@b']) {
    blocTest<RecuperarCubit, RecuperarState>(
      'invalid email "$email" -> Fallido without calling the repository',
      build: () => RecuperarCubit(repo),
      act: (c) => c.enviar(email),
      expect: () => [
        const RecuperarFallido(RecuperarCubit.mensajeCorreoInvalido),
      ],
      verify: (_) => verifyNever(() => repo.solicitarRecuperacion(any())),
    );
  }

  blocTest<RecuperarCubit, RecuperarState>(
    'HU 2.1 c3 404 CUENTA_NO_EXISTE -> the literal "not registered" message',
    build: () {
      when(() => repo.solicitarRecuperacion(any())).thenThrow(
        const ApiException(status: 404, message: 'x', code: 'CUENTA_NO_EXISTE'),
      );
      return RecuperarCubit(repo);
    },
    act: (c) => c.enviar('ana@test.com'),
    expect: () => [
      const RecuperarEnviando(),
      const RecuperarFallido(
        RecuperarCubit.mensajeCuentaNoExiste,
        codigo: 'CUENTA_NO_EXISTE',
      ),
    ],
  );

  blocTest<RecuperarCubit, RecuperarState>(
    '429 -> Fallido with the wait text, code and seconds to retry',
    build: () {
      when(() => repo.solicitarRecuperacion(any())).thenThrow(
        const ApiException(
          status: 429,
          message: 'Demasiadas solicitudes',
          code: 'DEMASIADAS_SOLICITUDES',
          reintentarEnSegundos: 90,
        ),
      );
      return RecuperarCubit(repo);
    },
    act: (c) => c.enviar('ana@test.com'),
    expect: () => [
      const RecuperarEnviando(),
      const RecuperarFallido(
        'Demasiados intentos, probá en 2 minutos',
        codigo: 'DEMASIADAS_SOLICITUDES',
        reintentarEnSegundos: 90,
      ),
    ],
  );

  blocTest<RecuperarCubit, RecuperarState>(
    'network failure -> Fallido(esSinConexion)',
    build: () {
      when(
        () => repo.solicitarRecuperacion(any()),
      ).thenThrow(const ApiException.sinConexion());
      return RecuperarCubit(repo);
    },
    act: (c) => c.enviar('ana@test.com'),
    expect: () => [
      const RecuperarEnviando(),
      const RecuperarFallido(
        'No se pudo conectar con el servidor',
        esSinConexion: true,
      ),
    ],
  );

  test('a send while another is in flight is ignored', () async {
    when(() => repo.solicitarRecuperacion(any())).thenAnswer((_) async {});
    final cubit = RecuperarCubit(repo);
    final primero = cubit.enviar('ana@test.com');
    await cubit.enviar('ana@test.com');
    await primero;
    verify(() => repo.solicitarRecuperacion(any())).called(1);
    await cubit.close();
  });

  test('a closed cubit does not emit when the call finishes', () async {
    when(() => repo.solicitarRecuperacion(any())).thenAnswer((_) async {});
    final cubit = RecuperarCubit(repo);
    final envio = cubit.enviar('ana@test.com');
    await cubit.close();
    await expectLater(envio, completes);
  });

  group('common errors', () {
    testErroresComunes('ends as Fallido and accepts a retry', (caso) async {
      when(() => repo.solicitarRecuperacion(any())).thenThrow(caso.error);
      final c = RecuperarCubit(repo);

      await c.enviar('ana@test.com');

      expect(
        c.state,
        RecuperarFallido(
          caso.mensaje,
          codigo: caso.error.code,
          esSinConexion: caso.esSinConexion,
        ),
      );
      when(() => repo.solicitarRecuperacion(any())).thenAnswer((_) async {});
      await c.enviar('ana@test.com');
      expect(c.state, const RecuperarEnviado(RecuperarCubit.mensajeNeutral));
    });
  });
}
