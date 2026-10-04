import 'package:bloc_test/bloc_test.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/features/auth/data/auth_repository.dart';
import 'package:crowdradar/features/auth/login/login_cubit.dart';
import 'package:crowdradar/features/auth/login/login_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _AuthRepoMock extends Mock implements AuthRepository {}

void main() {
  late _AuthRepoMock repo;
  setUp(() => repo = _AuthRepoMock());

  void caso(
    String descripcion,
    ApiException error,
    String mensaje, {
    String? codigo,
    int? espera,
  }) =>
      blocTest<LoginCubit, LoginState>(
        descripcion,
        build: () {
          when(() => repo.iniciarSesion(any(), any())).thenThrow(error);
          return LoginCubit(repo);
        },
        act: (c) => c.iniciarSesion('a@b.c', 'x'),
        expect: () => [
          const LoginEnviando(),
          LoginFallido(
            mensaje,
            codigo: codigo ?? error.code,
            reintentarEnSegundos: espera,
          ),
        ],
      );

  caso(
    'HU 1.1 c2 CREDENCIALES_INVALIDAS -> same text for wrong email or password',
    const ApiException(
      status: 401,
      message: 'Credenciales inválidas',
      code: 'CREDENCIALES_INVALIDAS',
    ),
    'Correo o contraseña incorrectos',
  );

  caso(
    'HU 1.1 c3 CUENTA_NO_EXISTE (DETALLADA) -> literal "no account" text',
    const ApiException(
      status: 404,
      message: 'x',
      code: 'CUENTA_NO_EXISTE',
    ),
    'No existe una cuenta con este correo',
  );

  caso(
    'CUENTA_SUSPENDIDA -> suspended text',
    const ApiException(status: 403, message: 'x', code: 'CUENTA_SUSPENDIDA'),
    'Tu cuenta está suspendida',
  );

  caso(
    '429 DEMASIADOS_INTENTOS with Retry-After 125s -> waits 3 minutes',
    const ApiException(
      status: 429,
      message: 'x',
      code: 'DEMASIADOS_INTENTOS',
      reintentarEnSegundos: 125,
    ),
    'Demasiados intentos, probá en 3 minutos',
    espera: 125,
  );

  caso(
    '429 DEMASIADAS_SOLICITUDES with Retry-After 60s -> singular minute',
    const ApiException(
      status: 429,
      message: 'x',
      code: 'DEMASIADAS_SOLICITUDES',
      reintentarEnSegundos: 60,
    ),
    'Demasiados intentos, probá en 1 minuto',
    espera: 60,
  );

  caso(
    '429 without Retry-After -> generic wait text',
    const ApiException(status: 429, message: 'x', code: 'DEMASIADOS_INTENTOS'),
    'Demasiados intentos, probá más tarde',
  );

  caso(
    'an unknown code keeps the server message',
    const ApiException(status: 500, message: 'Servidor caído', code: 'OTRO'),
    'Servidor caído',
  );
}
