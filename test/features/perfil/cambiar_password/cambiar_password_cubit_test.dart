import 'package:bloc_test/bloc_test.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/features/perfil/cambiar_password/cambiar_password_cubit.dart';
import 'package:crowdradar/features/perfil/cambiar_password/cambiar_password_state.dart';
import 'package:crowdradar/features/perfil/data/perfil_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../../helpers/errores_comunes.dart';

class _PerfilRepoMock extends Mock implements PerfilRepository {}

void main() {
  late _PerfilRepoMock repo;
  setUp(() => repo = _PerfilRepoMock());

  Future<void> Function() llamada() =>
      () => repo.cambiarPassword(
        actual: any(named: 'actual'),
        nueva: any(named: 'nueva'),
        confirmar: any(named: 'confirmar'),
      );

  void falla(ApiException e) => when(llamada()).thenThrow(e);

  Future<void> cambiarValido(CambiarPasswordCubit c) =>
      c.cambiar(actual: 'Vieja123', nueva: 'Nueva1234', confirmar: 'Nueva1234');

  blocTest<CambiarPasswordCubit, CambiarPasswordState>(
    'HU 2.3 c2 success -> Enviando, Exitoso',
    build: () {
      when(llamada()).thenAnswer((_) async {});
      return CambiarPasswordCubit(repo);
    },
    act: cambiarValido,
    expect: () => [
      const CambiarPasswordEnviando(),
      const CambiarPasswordExitoso(CambiarPasswordCubit.mensajeExito),
    ],
    verify: (_) => verify(
      () => repo.cambiarPassword(
        actual: 'Vieja123',
        nueva: 'Nueva1234',
        confirmar: 'Nueva1234',
      ),
    ).called(1),
  );

  blocTest<CambiarPasswordCubit, CambiarPasswordState>(
    'client mismatch -> Fallido without calling the repository',
    build: () => CambiarPasswordCubit(repo),
    act: (c) => c.cambiar(
      actual: 'Vieja123',
      nueva: 'Nueva1234',
      confirmar: 'Otra12345',
    ),
    expect: () => [
      const CambiarPasswordFallido(CambiarPasswordCubit.mensajeNoCoinciden),
    ],
    verify: (_) => verifyNever(llamada()),
  );

  blocTest<CambiarPasswordCubit, CambiarPasswordState>(
    'HU 2.3 c4 weak password -> Fallido(requisitosIncumplidos), no call',
    build: () => CambiarPasswordCubit(repo),
    act: (c) => c.cambiar(
      actual: 'Vieja123',
      nueva: 'secretaaa',
      confirmar: 'secretaaa',
    ),
    expect: () => [
      const CambiarPasswordFallido(
        CambiarPasswordCubit.mensajeNoCumple,
        requisitosIncumplidos: ['Al menos una mayúscula', 'Al menos un número'],
      ),
    ],
    verify: (_) => verifyNever(llamada()),
  );

  blocTest<CambiarPasswordCubit, CambiarPasswordState>(
    'HU 2.3 c3 422 PASSWORD_ACTUAL_INCORRECTA -> server message and code',
    build: () {
      falla(
        const ApiException(
          status: 422,
          message: 'La contraseña actual es incorrecta',
          code: 'PASSWORD_ACTUAL_INCORRECTA',
        ),
      );
      return CambiarPasswordCubit(repo);
    },
    act: cambiarValido,
    expect: () => [
      const CambiarPasswordEnviando(),
      const CambiarPasswordFallido(
        'La contraseña actual es incorrecta',
        codigo: 'PASSWORD_ACTUAL_INCORRECTA',
      ),
    ],
  );

  blocTest<CambiarPasswordCubit, CambiarPasswordState>(
    '422 PASSWORD_REPETIDA -> server message and code',
    build: () {
      falla(
        const ApiException(
          status: 422,
          message: 'La nueva contraseña debe ser distinta',
          code: 'PASSWORD_REPETIDA',
        ),
      );
      return CambiarPasswordCubit(repo);
    },
    act: cambiarValido,
    expect: () => [
      const CambiarPasswordEnviando(),
      const CambiarPasswordFallido(
        'La nueva contraseña debe ser distinta',
        codigo: 'PASSWORD_REPETIDA',
      ),
    ],
  );

  blocTest<CambiarPasswordCubit, CambiarPasswordState>(
    '400 errors[] are mapped to requisitosIncumplidos',
    build: () {
      falla(
        const ApiException(
          status: 400,
          message: 'Validación fallida',
          code: 'VALIDACION_FALLIDA',
          errors: [
            ErrorCampo(campo: 'nuevaPassword', mensaje: 'Falta una mayúscula'),
            ErrorCampo(campo: 'nuevaPassword', mensaje: 'Falta un número'),
          ],
        ),
      );
      return CambiarPasswordCubit(repo);
    },
    act: cambiarValido,
    expect: () => [
      const CambiarPasswordEnviando(),
      const CambiarPasswordFallido(
        'Validación fallida',
        codigo: 'VALIDACION_FALLIDA',
        requisitosIncumplidos: ['Falta una mayúscula', 'Falta un número'],
      ),
    ],
  );

  blocTest<CambiarPasswordCubit, CambiarPasswordState>(
    '429 -> Fallido with the wait text and the seconds to retry',
    build: () {
      falla(
        const ApiException(
          status: 429,
          message: 'Demasiadas solicitudes',
          code: 'DEMASIADAS_SOLICITUDES',
          reintentarEnSegundos: 125,
        ),
      );
      return CambiarPasswordCubit(repo);
    },
    act: cambiarValido,
    expect: () => [
      const CambiarPasswordEnviando(),
      const CambiarPasswordFallido(
        'Demasiados intentos, probá en 3 minutos',
        codigo: 'DEMASIADAS_SOLICITUDES',
        reintentarEnSegundos: 125,
      ),
    ],
  );

  blocTest<CambiarPasswordCubit, CambiarPasswordState>(
    'R4-1201 offline during the change -> uncertain result with its own copy',
    build: () {
      falla(const ApiException.sinConexion());
      return CambiarPasswordCubit(repo);
    },
    act: cambiarValido,
    expect: () => [
      const CambiarPasswordEnviando(),
      const CambiarPasswordFallido(
        CambiarPasswordCubit.mensajeResultadoIncierto,
        esSinConexion: true,
        resultadoIncierto: true,
      ),
    ],
  );

  test('R4-1201 the uncertain copy tells the user to try the new password', () {
    expect(
      CambiarPasswordCubit.mensajeResultadoIncierto,
      'No pudimos confirmar el cambio. Si no podés entrar con la contraseña '
      'actual, probá con la nueva.',
    );
  });

  blocTest<CambiarPasswordCubit, CambiarPasswordState>(
    'a server error is NOT an uncertain result',
    build: () {
      falla(const ApiException(status: 500, message: 'Caído'));
      return CambiarPasswordCubit(repo);
    },
    act: cambiarValido,
    expect: () => [
      const CambiarPasswordEnviando(),
      const CambiarPasswordFallido('Caído'),
    ],
  );

  test('a submit while another is in flight is ignored', () async {
    when(llamada()).thenAnswer((_) async {});
    final cubit = CambiarPasswordCubit(repo);
    final primero = cambiarValido(cubit);
    await cambiarValido(cubit);
    await primero;
    verify(llamada()).called(1);
    await cubit.close();
  });

  test('a closed cubit does not emit when the call finishes', () async {
    when(llamada()).thenAnswer((_) async {});
    final cubit = CambiarPasswordCubit(repo);
    final envio = cambiarValido(cubit);
    await cubit.close();
    await expectLater(envio, completes);
  });

  group('common errors', () {
    testErroresComunes(
      'ends as Fallido; only transport failures are uncertain',
      (caso) async {
        falla(caso.error);
        final c = CambiarPasswordCubit(repo);

        await cambiarValido(c);

        expect(
          c.state,
          CambiarPasswordFallido(
            caso.esSinConexion
                ? CambiarPasswordCubit.mensajeResultadoIncierto
                : caso.mensaje,
            codigo: caso.error.code,
            esSinConexion: caso.esSinConexion,
            resultadoIncierto: caso.esSinConexion,
          ),
        );
        await c.close();
      },
    );
  });
}
