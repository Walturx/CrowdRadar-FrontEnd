import 'dart:convert';
import 'dart:io';

import 'package:crowdradar/core/config/entorno.dart';
import 'package:crowdradar/core/network/api_client.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/network/interceptores/auth_interceptor.dart';
import 'package:crowdradar/core/network/interceptores/interceptor_api.dart';
import 'package:crowdradar/core/network/interceptores/sesion_expirada_interceptor.dart';
import 'package:crowdradar/core/session/motivo_cierre.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../fakes/registro_falso.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _entorno = Entorno(apiUrl: 'http://api.test');

http.Response _json(int status, Object? body) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

ApiClient _cliente(
  MockClientHandler handler, {
  List<InterceptorApi> interceptores = const [],
  Duration timeout = const Duration(seconds: 15),
  RegistroFalso? registro,
  DateTime Function()? ahora,
}) =>
    ApiClient(
      MockClient(handler),
      _entorno,
      interceptores: interceptores,
      timeout: timeout,
      registro: registro,
      ahora: ahora,
    );

class _InterceptorQueFalla extends InterceptorApi {
  final bool alEnviar;

  _InterceptorQueFalla({this.alEnviar = false});

  @override
  void antesDeEnviar(SolicitudApi solicitud) {
    if (alEnviar) throw StateError('boom antes');
  }

  @override
  Future<void> alRecibirError(ApiException error, SolicitudApi solicitud) async {
    if (!alEnviar) throw StateError('boom despues');
  }
}

Object? _identidad(Object? d) => d;

Future<ApiException> _capturar(Future<Object?> Function() accion) async {
  try {
    await accion();
  } catch (e) {
    expect(e, isA<ApiException>());
    return e as ApiException;
  }
  fail('expected ApiException');
}

void main() {
  group('ApiClient success', () {
    test('S3.1 200 {message,data} yields typed RespuestaApi', () async {
      final api = _cliente((r) async {
        expect(r.url.toString(), 'http://api.test/api/ping');
        expect(r.headers['Content-Type'], contains('application/json'));
        return _json(200, {
          'message': 'ok',
          'data': {'n': 7},
        });
      });

      final res = await api.get<int>(
        '/api/ping',
        parser: (d) => (d as Map<String, dynamic>)['n'] as int,
      );

      expect(res.mensaje, 'ok');
      expect(res.datos, 7);
    });

    test('S2.2 uses the configured apiUrl for post with JSON body', () async {
      late http.Request visto;
      final api = _cliente((r) async {
        visto = r;
        return _json(201, {
          'message': 'creado',
          'data': {'id': 1},
        });
      });

      final res = await api.post<Object?>(
        '/api/x',
        body: {'a': 1},
        parser: _identidad,
      );

      expect(visto.method, 'POST');
      expect(visto.url.host, 'api.test');
      expect(jsonDecode(visto.body), {'a': 1});
      expect(res.mensaje, 'creado');
    });

    test('put sends PUT and empty 2xx body yields null datos', () async {
      late String metodo;
      final api = _cliente((r) async {
        metodo = r.method;
        return http.Response('', 204);
      });

      final res =
          await api.put<Object?>('/api/x', body: {}, parser: _identidad);

      expect(metodo, 'PUT');
      expect(res.datos, isNull);
      expect(res.mensaje, '');
    });
  });

  group('ApiClient errors', () {
    test('S3.2 422 body becomes ApiException with code and errors', () async {
      final api = _cliente((_) async => _json(422, {
            'message': 'Datos inválidos.',
            'code': 'VALIDACION_FALLIDA',
            'errors': [
              {'campo': 'email', 'mensaje': 'Email inválido'},
            ],
          }));

      final e = await _capturar(
          () => api.get<Object?>('/api/x', parser: _identidad));

      expect(e.status, 422);
      expect(e.message, 'Datos inválidos.');
      expect(e.code, 'VALIDACION_FALLIDA');
      expect(e.errors.single.campo, 'email');
      expect(e.errors.single.mensaje, 'Email inválido');
    });

    test('429 keeps the Retry-After seconds on the exception', () async {
      final api = _cliente((_) async => http.Response.bytes(
            utf8.encode(jsonEncode({'code': 'DEMASIADOS_INTENTOS'})),
            429,
            headers: {'retry-after': '120'},
          ));

      final e = await _capturar(
          () => api.get<Object?>('/api/x', parser: _identidad));

      expect(e.reintentarEnSegundos, 120);
    });

    group('Retry-After', () {
      final ahora = DateTime.utc(2026, 10, 4, 12);

      Future<int?> espera(String? cabecera) async {
        final api = _cliente(
          (_) async => http.Response.bytes(
            utf8.encode(jsonEncode({'code': 'X'})),
            429,
            headers: {'retry-after': ?cabecera},
          ),
          ahora: () => ahora,
        );
        final e = await _capturar(
            () => api.get<Object?>('/api/x', parser: _identidad));
        return e.reintentarEnSegundos;
      }

      test('an HTTP-date is the difference from now', () async {
        final fecha = HttpDate.format(ahora.add(const Duration(seconds: 90)));

        expect(await espera(fecha), 90);
      });

      test('an HTTP-date in the past clamps to zero', () async {
        final fecha = HttpDate.format(ahora.subtract(const Duration(hours: 1)));

        expect(await espera(fecha), 0);
      });

      test('a negative number of seconds clamps to zero', () async {
        expect(await espera('-5'), 0);
      });

      test('a huge wait is capped at one hour', () async {
        expect(await espera('86400'), 3600);
        expect(
          await espera(HttpDate.format(ahora.add(const Duration(days: 2)))),
          3600,
        );
      });

      test('a missing or unparseable header has none', () async {
        expect(await espera(null), isNull);
        expect(await espera('pronto'), isNull);
      });
    });

    test('S3.6 non-JSON failure falls back to the provided message', () async {
      final api = _cliente((_) async => http.Response('<html>', 500));

      final e = await _capturar(() => api.post<Object?>('/api/x',
          parser: _identidad, mensajeError: 'Error al registrar usuario'));

      expect(e.status, 500);
      expect(e.message, 'Error al registrar usuario');
      expect(e.code, isNull);
      expect(e.errors, isEmpty);
    });

    test('S3.6 JSON lacking message uses default message', () async {
      final api = _cliente((_) async => _json(400, {'otro': 1}));

      final e = await _capturar(
          () => api.get<Object?>('/api/x', parser: _identidad));

      expect(e.message, ApiException.mensajePorDefecto);
      expect(e.code, isNull);
    });

    test('S3.6 2xx with malformed JSON throws ApiException', () async {
      final api = _cliente((_) async => http.Response('{no', 200));

      final e = await _capturar(
          () => api.get<Object?>('/api/x', parser: _identidad));

      expect(e.status, 200);
    });

    test('S3.5 SocketException maps to sinConexion', () async {
      final api = _cliente((_) async => throw const SocketException('down'));

      final e = await _capturar(
          () => api.get<Object?>('/api/x', parser: _identidad));

      expect(e.esSinConexion, isTrue);
      expect(e.message, ApiException.mensajeSinConexion);
    });

    test('S3.5 timeout maps to sinConexion', () async {
      final api = _cliente(
        (_) => Future.delayed(
            const Duration(milliseconds: 300), () => _json(200, {})),
        timeout: const Duration(milliseconds: 20),
      );

      final e = await _capturar(
          () => api.get<Object?>('/api/x', parser: _identidad));

      expect(e.esSinConexion, isTrue);
    });

    test('S3.5 http.ClientException maps to sinConexion', () async {
      final api = _cliente((_) async => throw http.ClientException('boom'));

      final e = await _capturar(
          () => api.get<Object?>('/api/x', parser: _identidad));

      expect(e.esSinConexion, isTrue);
    });
  });

  group('ApiClient review fixes', () {
    test('R3-006 interceptor failing before send becomes INTERCEPTOR', () async {
      final api = _cliente((_) async => _json(200, {}),
          interceptores: [_InterceptorQueFalla(alEnviar: true)]);

      final e = await _capturar(
          () => api.get<Object?>('/api/x', parser: _identidad));

      expect(e.code, ApiException.codigoInterceptor);
      expect(e.status, -1);
    });

    test('R3-006 interceptor failing on error does not mask the original',
        () async {
      final api = _cliente((_) async => _json(500, {'message': 'real'}),
          interceptores: [_InterceptorQueFalla()]);

      final e = await _capturar(
          () => api.get<Object?>('/api/x', parser: _identidad));

      expect(e.status, 500);
      expect(e.message, 'real');
    });

    test('R3-006 SesionExpiradaInterceptor awaits expirar', () async {
      var terminado = false;
      final api = _cliente(
        (_) async => _json(401, {'message': 'x'}),
        interceptores: [
          SesionExpiradaInterceptor((_) async {
            await Future<void>.delayed(const Duration(milliseconds: 20));
            terminado = true;
          }),
        ],
      );

      await _capturar(() => api.get<Object?>('/api/users/p', parser: _identidad));

      expect(terminado, isTrue);
    });

    test('R3-006 SesionExpiradaInterceptor swallows and logs expirar failure',
        () async {
      final registro = RegistroFalso();
      final api = _cliente(
        (_) async => _json(401, {'message': 'x'}),
        registro: registro,
        interceptores: [
          SesionExpiradaInterceptor((_) async => throw StateError('x'),
              registro: registro),
        ],
      );

      final e = await _capturar(
          () => api.get<Object?>('/api/users/p', parser: _identidad));

      expect(e.status, 401);
      expect(registro.registros, isNotEmpty);
    });

    for (final (nombre, error) in <(String, Object)>[
      ('StateError', StateError('x')),
      ('ArgumentError', ArgumentError('x')),
      ('RangeError', RangeError('x')),
    ]) {
      test('R3-006 parser throwing $nombre becomes RESPUESTA_INVALIDA',
          () async {
        final registro = RegistroFalso();
        final api = _cliente((_) async => _json(200, {'data': 1}),
            registro: registro);

        final e = await _capturar(() => api.get<Object?>('/api/x',
            parser: (_) => throw error, mensajeError: 'Fallo'));

        expect(e.code, ApiException.codigoRespuestaInvalida);
        expect(e.message, 'Fallo');
        expect(registro.registros, hasLength(1));
      });
    }

    test('parser ApiException passes through untouched', () async {
      final api = _cliente((_) async => _json(200, {'data': 1}));

      final e = await _capturar(() => api.get<Object?>('/api/x',
          parser: (_) => throw const ApiException(status: 7, message: 'm')));

      expect(e.status, 7);
    });

    test('R4-007 transport failure is reported', () async {
      final registro = RegistroFalso();
      final api = _cliente((_) async => throw http.ClientException('x'),
          registro: registro);

      await _capturar(() => api.get<Object?>('/api/x', parser: _identidad));

      expect(registro.registros, hasLength(1));
    });
  });

  group('Interceptors', () {
    test('S3.7 Bearer header present with token, absent without', () async {
      final headers = <Map<String, String>>[];
      String? token = 'abc';
      final api = _cliente(
        (r) async {
          headers.add(r.headers);
          return _json(200, {'message': '', 'data': null});
        },
        interceptores: [AuthInterceptor(() => token)],
      );

      await api.get<Object?>('/api/x', parser: _identidad);
      token = null;
      await api.get<Object?>('/api/x', parser: _identidad);

      expect(headers[0]['Authorization'], 'Bearer abc');
      expect(headers[1].containsKey('Authorization'), isFalse);
    });

    test('S3.3 401 outside /api/auth/ expires the session once', () async {
      final motivos = <MotivoCierre>[];
      final api = _cliente(
        (_) async => _json(401, {'message': 'No autenticado'}),
        interceptores: [SesionExpiradaInterceptor((m) async => motivos.add(m))],
      );

      final e = await _capturar(
          () => api.get<Object?>('/api/users/profile', parser: _identidad));

      expect(e.status, 401);
      expect(motivos, [MotivoCierre.sesionExpirada]);
    });

    test('S3.4 401 on /api/auth/login does not expire the session', () async {
      final motivos = <MotivoCierre>[];
      final api = _cliente(
        (_) async => _json(401, {'message': 'Credenciales inválidas'}),
        interceptores: [SesionExpiradaInterceptor((m) async => motivos.add(m))],
      );

      final e = await _capturar(() => api.post<Object?>('/api/auth/login',
          body: {}, parser: _identidad));

      expect(e.status, 401);
      expect(motivos, isEmpty);
    });

    test('CUENTA_SUSPENDIDA expires with cuentaSuspendida', () async {
      final motivos = <MotivoCierre>[];
      final api = _cliente(
        (_) async => _json(
            403, {'message': 'Suspendida', 'code': 'CUENTA_SUSPENDIDA'}),
        interceptores: [SesionExpiradaInterceptor((m) async => motivos.add(m))],
      );

      await _capturar(
          () => api.get<Object?>('/api/users/profile', parser: _identidad));

      expect(motivos, [MotivoCierre.cuentaSuspendida]);
    });

    test('other errors do not expire the session', () async {
      final motivos = <MotivoCierre>[];
      final api = _cliente(
        (_) async => _json(500, {'message': 'x'}),
        interceptores: [SesionExpiradaInterceptor((m) async => motivos.add(m))],
      );

      await _capturar(
          () => api.get<Object?>('/api/users/profile', parser: _identidad));

      expect(motivos, isEmpty);
    });
  });
}
