import 'package:bloc_test/bloc_test.dart';
import 'package:crowdradar/core/models/user_model.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/features/auth/data/auth_repository.dart';
import 'package:crowdradar/features/auth/login/login_cubit.dart';
import 'package:crowdradar/features/auth/login/login_state.dart';
import 'package:crowdradar/features/auth/registro/registro_cubit.dart';
import 'package:crowdradar/features/auth/registro/registro_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _AuthRepoMock extends Mock implements AuthRepository {}

const _user = UserModel(id: 1, nombre: 'Ana');

void main() {
  late _AuthRepoMock repo;
  setUp(() => repo = _AuthRepoMock());

  group('LoginCubit', () {
    blocTest<LoginCubit, LoginState>(
      'S8.1 success -> Enviando, Exitoso(usuario)',
      build: () {
        when(() => repo.iniciarSesion('a@b.c', 'x'))
            .thenAnswer((_) async => _user);
        return LoginCubit(repo);
      },
      act: (c) => c.iniciarSesion('a@b.c', 'x'),
      expect: () => [const LoginEnviando(), const LoginExitoso(_user)],
    );

    blocTest<LoginCubit, LoginState>(
      'S8.2 ApiException -> Fallido(message, code)',
      build: () {
        when(() => repo.iniciarSesion(any(), any())).thenThrow(
            const ApiException(
                status: 401,
                message: 'Credenciales inválidas',
                code: 'CREDENCIALES_INVALIDAS'));
        return LoginCubit(repo);
      },
      act: (c) => c.iniciarSesion('a@b.c', 'x'),
      expect: () => [
        const LoginEnviando(),
        const LoginFallido('Credenciales inválidas',
            codigo: 'CREDENCIALES_INVALIDAS'),
      ],
    );

    blocTest<LoginCubit, LoginState>(
      'S8.5 network failure -> Fallido(sinConexion)',
      build: () {
        when(() => repo.iniciarSesion(any(), any()))
            .thenThrow(const ApiException.sinConexion());
        return LoginCubit(repo);
      },
      act: (c) => c.iniciarSesion('a@b.c', 'x'),
      expect: () => [
        const LoginEnviando(),
        const LoginFallido('No se pudo conectar con el servidor',
            esSinConexion: true),
      ],
    );

    blocTest<LoginCubit, LoginState>(
      'R4-101 unexpected error -> generic message, no toString leak',
      build: () {
        when(() => repo.iniciarSesion(any(), any()))
            .thenThrow(StateError('boom'));
        return LoginCubit(repo);
      },
      act: (c) => c.iniciarSesion('a@b.c', 'x'),
      expect: () => [
        const LoginEnviando(),
        const LoginFallido('Ocurrió un error inesperado'),
      ],
    );
  });

  test('R4-101 FormatException does not leak its text', () async {
    when(() => repo.iniciarSesion(any(), any()))
        .thenThrow(const FormatException('token=secreto'));
    final c = LoginCubit(repo);

    await c.iniciarSesion('a', 'b');

    final estado = c.state as LoginFallido;
    expect(estado.mensaje, 'Ocurrió un error inesperado');
    expect(estado.esSinConexion, isFalse);
    expect(estado.mensaje, isNot(contains('secreto')));
  });

  group('RegistroCubit', () {
    Future<void> registrar(RegistroCubit c) => c.registrar(
          nombre: 'Ana',
          apellido: 'Paz',
          email: 'a@b.c',
          password: 'Secreta1',
          telefono: '',
          distrito: 'Lima',
        );

    When<Future<UserModel>> cuandoRegistra() => when(() => repo.registrar(
          nombre: any(named: 'nombre'),
          apellido: any(named: 'apellido'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          telefono: any(named: 'telefono'),
          distrito: any(named: 'distrito'),
        ));

    blocTest<RegistroCubit, RegistroState>(
      'S8.3 success -> Enviando, Exitoso',
      build: () {
        cuandoRegistra().thenAnswer((_) async => _user);
        return RegistroCubit(repo);
      },
      act: registrar,
      expect: () => [const RegistroEnviando(), const RegistroExitoso()],
    );

    blocTest<RegistroCubit, RegistroState>(
      'S8.3 409 -> Fallido(message) with empty field errors',
      build: () {
        cuandoRegistra().thenThrow(const ApiException(
            status: 409, message: 'El email ya está registrado'));
        return RegistroCubit(repo);
      },
      act: registrar,
      expect: () => [
        const RegistroEnviando(),
        const RegistroFallido('El email ya está registrado'),
      ],
    );

    blocTest<RegistroCubit, RegistroState>(
      '400 field errors map to erroresPorCampo',
      build: () {
        cuandoRegistra().thenThrow(const ApiException(
          status: 400,
          message: 'Datos inválidos.',
          errors: [ErrorCampo(campo: 'password', mensaje: 'Mínimo 8 caracteres')],
        ));
        return RegistroCubit(repo);
      },
      act: registrar,
      expect: () => [
        const RegistroEnviando(),
        const RegistroFallido('Datos inválidos.',
            erroresPorCampo: {'password': 'Mínimo 8 caracteres'}),
      ],
    );

    blocTest<RegistroCubit, RegistroState>(
      'R4-101 unexpected error -> generic message',
      build: () {
        cuandoRegistra().thenThrow(StateError('boom'));
        return RegistroCubit(repo);
      },
      act: registrar,
      expect: () => [
        const RegistroEnviando(),
        const RegistroFallido('Ocurrió un error inesperado'),
      ],
    );

    blocTest<RegistroCubit, RegistroState>(
      'R4-101 sinConexion flag is exposed',
      build: () {
        cuandoRegistra().thenThrow(const ApiException.sinConexion());
        return RegistroCubit(repo);
      },
      act: registrar,
      verify: (c) =>
          expect((c.state as RegistroFallido).esSinConexion, isTrue),
    );
  });
}
