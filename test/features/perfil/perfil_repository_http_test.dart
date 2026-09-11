import 'dart:convert';

import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/session/session_service.dart';
import 'package:crowdradar/features/perfil/data/perfil_repository_http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../fakes/http_falso.dart';
import '../../fakes/jwt_falso.dart';

const _usuarioJson = {
  'id': 1,
  'nombre': 'Ana',
  'apellido': 'Paz',
  'email': 'ana@test.com',
  'telefono': '987654321',
  'distrito': 'Miraflores',
  'rol': 'USUARIO',
  'status': 'ACTIVO',
  'puntosKarma': 30,
};

/// `data` exactly as the backend sends it for GET/PUT /api/users/profile.
Map<String, Object?> _perfil(Map<String, Object?> user) => {'user': user};

void main() {
  late SessionService sesion;
  http.Request? visto;

  PerfilRepositoryHttp repo(int status, Object? body) {
    visto = null;
    final api = apiClientPrueba((r) async {
      visto = r;
      return respuestaJson(status, body);
    }, sesion);
    return PerfilRepositoryHttp(api, sesion);
  }

  setUp(() => sesion = SessionService.instance..reiniciar());
  tearDown(() => sesion.reiniciar());

  group('sin sesión', () {
    test(
      'obtener fails with "No hay sesión activa" and sends nothing',
      () async {
        final r = repo(200, {'data': _perfil(_usuarioJson)});

        await expectLater(
          r.obtener(),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              'No hay sesión activa',
            ),
          ),
        );
        expect(visto, isNull);
      },
    );

    test(
      'actualizar fails with "No hay sesión activa" and sends nothing',
      () async {
        final r = repo(200, {'data': _perfil(_usuarioJson)});

        await expectLater(
          r.actualizar({'nombre': 'x'}),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              'No hay sesión activa',
            ),
          ),
        );
        expect(visto, isNull);
      },
    );
  });

  group('con sesión', () {
    setUp(() => sesion.iniciar('tkn', usuarioPrueba));

    test(
      'S8.4 obtener GETs the profile with Bearer and parses the user',
      () async {
        final r = repo(200, {'message': 'ok', 'data': _perfil(_usuarioJson)});

        final user = await r.obtener();

        expect(visto!.method, 'GET');
        expect(visto!.url.path, '/api/users/profile');
        expect(visto!.headers['Authorization'], 'Bearer tkn');
        expect(user.id, 1);
        expect(user.nombre, 'Ana');
        expect(user.apellido, 'Paz');
        expect(user.email, 'ana@test.com');
        expect(user.telefono, '987654321');
        expect(user.distrito, 'Miraflores');
        expect(user.puntosKarma, 30);
      },
    );

    test(
      'obtener error without message falls back to the Sprint 1 text',
      () async {
        final r = repo(500, {});

        await expectLater(
          r.obtener(),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              'Error al obtener el perfil',
            ),
          ),
        );
      },
    );

    test(
      'S8.4 actualizar PUTs the changes and updates the session user',
      () async {
        final r = repo(200, {
          'message': 'ok',
          'data': _perfil({..._usuarioJson, 'nombre': 'Beatriz'}),
        });

        final user = await r.actualizar({'nombre': 'Beatriz'});

        expect(visto!.method, 'PUT');
        expect(visto!.url.path, '/api/users/profile');
        expect(jsonDecode(visto!.body), {'nombre': 'Beatriz'});
        expect(user.nombre, 'Beatriz');
        expect(user.telefono, '987654321');
        expect(user.distrito, 'Miraflores');
        expect(sesion.usuario?.nombre, 'Beatriz');
        expect(sesion.usuario?.email, 'ana@test.com');
      },
    );

    test(
      'actualizar error keeps the session user and falls back to the text',
      () async {
        final r = repo(500, {});

        await expectLater(
          r.actualizar({'nombre': 'x'}),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              'Error al actualizar el perfil',
            ),
          ),
        );
        expect(sesion.usuario, usuarioPrueba);
      },
    );

    test(
      'cambiarPassword PUTs the three fields to /api/users/password',
      () async {
        final r = repo(200, {'message': 'ok'});

        await r.cambiarPassword(
          actual: 'Vieja1aa',
          nueva: 'Nueva1aa',
          confirmar: 'Nueva1aa',
        );

        expect(visto!.method, 'PUT');
        expect(visto!.url.path, '/api/users/password');
        expect(jsonDecode(visto!.body), {
          'passwordActual': 'Vieja1aa',
          'nuevaPassword': 'Nueva1aa',
          'confirmarPassword': 'Nueva1aa',
        });
      },
    );
  });
}
