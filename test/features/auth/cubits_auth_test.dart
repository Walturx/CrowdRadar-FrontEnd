import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:crowdradar/core/models/user_model.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/features/auth/data/auth_repository.dart';
import 'package:crowdradar/features/auth/login/login_cubit.dart';
import 'package:crowdradar/features/auth/login/login_state.dart';
import 'package:crowdradar/features/auth/registro/registro_cubit.dart';
import 'package:crowdradar/features/auth/registro/registro_state.dart';
import 'package:crowdradar/core/session/session_service.dart';
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

  group('R3-101 value equality of states holding a user', () {
    test('two separately built identical users give equal LoginExitoso', () {
      final a = UserModel.fromJson(const {'id': 1, 'nombre': 'Ana'});
      final b = UserModel.fromJson(const {'id': 1, 'nombre': 'Ana'});

      expect(identical(a, b), isFalse);
      expect(LoginExitoso(a), LoginExitoso(b));
      expect(a.hashCode, b.hashCode);
    });

    test('users that differ in one field are not equal', () {
      expect(
        const UserModel(id: 1, nombre: 'Ana'),
        isNot(const UserModel(id: 1, nombre: 'Beatriz')),
      );
    });
  });

  blocTest<LoginCubit, LoginState>(
    'R3-F02 storage failure on login surfaces the storage message',
    build: () {
      when(() => repo.iniciarSesion(any(), any()))
          .thenThrow(ErrorAlmacenamientoSesion(StateError('keystore')));
      return LoginCubit(repo);
    },
    act: (c) => c.iniciarSesion('a@b.c', 'x'),
    verify: (c) {
      final estado = c.state as LoginFallido;
      expect(estado.mensaje, contains('guardar la sesión'));
      expect(estado.mensaje, isNot('Ocurrió un error inesperado'));
    },
  );

  group('R3-109 a second submit while a request is in flight is ignored', () {
    test('LoginCubit sends one request for a double submit', () async {
      final pendiente = Completer<UserModel>();
      when(() => repo.iniciarSesion(any(), any()))
          .thenAnswer((_) => pendiente.future);
      final cubit = LoginCubit(repo);

      final primero = cubit.iniciarSesion('a@b.c', 'x');
      final segundo = cubit.iniciarSesion('a@b.c', 'x');
      pendiente.complete(_user);
      await Future.wait([primero, segundo]);

      verify(() => repo.iniciarSesion(any(), any())).called(1);
      expect(cubit.state, const LoginExitoso(_user));
    });

    test('LoginCubit accepts a new submit after a failure', () async {
      when(() => repo.iniciarSesion(any(), any()))
          .thenThrow(const ApiException.sinConexion());
      final cubit = LoginCubit(repo);

      await cubit.iniciarSesion('a@b.c', 'x');
      await cubit.iniciarSesion('a@b.c', 'x');

      verify(() => repo.iniciarSesion(any(), any())).called(2);
    });

    test('RegistroCubit sends one request for a double submit', () async {
      final pendiente = Completer<UserModel>();
      when(
        () => repo.registrar(
          nombre: any(named: 'nombre'),
          apellido: any(named: 'apellido'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          telefono: any(named: 'telefono'),
          distrito: any(named: 'distrito'),
        ),
      ).thenAnswer((_) => pendiente.future);
      final cubit = RegistroCubit(repo);
      Future<void> enviar() => cubit.registrar(
            nombre: 'a',
            apellido: 'b',
            email: 'c@d.e',
            password: 'Secreta12',
            telefono: '999999999',
            distrito: 'x',
          );

      final primero = enviar();
      final segundo = enviar();
      pendiente.complete(_user);
      await Future.wait([primero, segundo]);

      verify(
        () => repo.registrar(
          nombre: any(named: 'nombre'),
          apellido: any(named: 'apellido'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          telefono: any(named: 'telefono'),
          distrito: any(named: 'distrito'),
        ),
      ).called(1);
    });
  });
}
