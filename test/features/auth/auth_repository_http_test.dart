import 'dart:convert';

import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/session/session_service.dart';
import 'package:crowdradar/features/auth/data/auth_repository_http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../fakes/http_falso.dart';

const _usuarioJson = {
  'id': 7,
  'nombre': 'Ana',
  'apellido': 'Paz',
  'email': 'ana@test.com',
  'rol': 'USUARIO',
  'status': 'ACTIVO',
};

void main() {
  late SessionService sesion;
  late http.Request visto;

  AuthRepositoryHttp repo(int status, Object? body) {
    final api = apiClientPrueba((r) async {
      visto = r;
      return respuestaJson(status, body);
    }, sesion);
    return AuthRepositoryHttp(api, sesion);
  }

  setUp(() => sesion = SessionService.instance..reiniciar());
  tearDown(() => sesion.reiniciar());

  group('iniciarSesion', () {
    test('S8.1 success posts credentials, starts the session, returns the user',
        () async {
      final r = repo(200, {
        'message': 'ok',
        'data': {'token': 'tkn', 'user': _usuarioJson},
      });

      final user = await r.iniciarSesion('ana@test.com', 'Secreta1');

      expect(visto.method, 'POST');
      expect(visto.url.toString(), 'http://api.test/api/auth/login');
      expect(jsonDecode(visto.body),
          {'email': 'ana@test.com', 'password': 'Secreta1'});
      expect(user.id, 7);
      expect(sesion.token, 'tkn');
      expect(sesion.usuario?.email, 'ana@test.com');
    });

    test('S8.2 401 surfaces body.message and keeps the session closed',
        () async {
      final r = repo(401, {
        'message': 'Credenciales inválidas',
        'code': 'CREDENCIALES_INVALIDAS',
      });

      await expectLater(
        r.iniciarSesion('a@b.c', 'x'),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Credenciales inválidas')
            .having((e) => e.code, 'code', 'CREDENCIALES_INVALIDAS')),
      );
      expect(sesion.token, isNull);
    });

    test('error without message falls back to the Sprint 1 text', () async {
      final r = repo(500, {});

      await expectLater(
        r.iniciarSesion('a@b.c', 'x'),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Error al iniciar sesión')),
      );
    });
  });

  group('registrar', () {
    Future<Object?> registrar(AuthRepositoryHttp r) => r.registrar(
          nombre: 'Ana',
          apellido: 'Paz',
          email: 'ana@test.com',
          password: 'Secreta1',
          telefono: '912345678',
          distrito: 'Miraflores',
        );

    test('S8.3 success posts the six fields and returns the user', () async {
      final r = repo(201, {'message': 'creado', 'data': _usuarioJson});

      final user = await r.registrar(
        nombre: 'Ana',
        apellido: 'Paz',
        email: 'ana@test.com',
        password: 'Secreta1',
        telefono: '912345678',
        distrito: 'Miraflores',
      );

      expect(visto.url.path, '/api/auth/register');
      expect(jsonDecode(visto.body), {
        'nombre': 'Ana',
        'apellido': 'Paz',
        'email': 'ana@test.com',
        'password': 'Secreta1',
        'telefono': '912345678',
        'distrito': 'Miraflores',
      });
      expect(user.email, 'ana@test.com');
      expect(sesion.token, isNull);
    });

    test('S8.3 409 shows the backend message', () async {
      final r = repo(409, {
        'message': 'El email ya está registrado',
        'code': 'EMAIL_DUPLICADO',
      });

      await expectLater(
        registrar(r),
        throwsA(isA<ApiException>().having(
            (e) => e.message, 'message', 'El email ya está registrado')),
      );
    });

    test('error without message falls back to the Sprint 1 text', () async {
      final api = apiClientPrueba(
          (_) async => http.Response('<html>', 500), sesion);

      await expectLater(
        registrar(AuthRepositoryHttp(api, sesion)),
        throwsA(isA<ApiException>().having(
            (e) => e.message, 'message', 'Error al registrar usuario')),
      );
    });
  });

  test('S8.5 network failure maps to sinConexion', () async {
    final api =
        apiClientPrueba((_) async => throw http.ClientException('x'), sesion);

    await expectLater(
      AuthRepositoryHttp(api, sesion).iniciarSesion('a', 'b'),
      throwsA(isA<ApiException>()
          .having((e) => e.esSinConexion, 'sinConexion', true)),
    );
  });

  test('solicitarRecuperacion posts the email to /api/auth/recuperar',
      () async {
    final r = repo(200, {'message': 'Si el correo existe...'});

    await r.solicitarRecuperacion('ana@test.com');

    expect(visto.url.path, '/api/auth/recuperar');
    expect(jsonDecode(visto.body), {'email': 'ana@test.com'});
  });
}
