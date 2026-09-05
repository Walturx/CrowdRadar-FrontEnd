import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/entorno.dart';
import '../logging/registro_errores.dart';
import 'api_exception.dart';
import 'interceptores/interceptor_api.dart';
import '../utils/lectura_json.dart';
import 'respuesta_api.dart';

typedef ParserApi<T> = T Function(Object? datos);

/// Facade over `http`: single HTTP entry point: JSON, 15 s timeout, typed envelope, interceptors.
class ApiClient {
  static const Duration timeoutPorDefecto = Duration(seconds: 15);

  final http.Client _cliente;
  final Entorno _entorno;
  final List<InterceptorApi> _interceptores;
  final Duration _timeout;
  final RegistroErrores _registro;

  ApiClient(
    this._cliente,
    this._entorno, {
    List<InterceptorApi> interceptores = const [],
    Duration timeout = timeoutPorDefecto,
    RegistroErrores? registro,
  })  : _interceptores = interceptores,
        _timeout = timeout,
        _registro = registro ?? const RegistroErroresConsola();

  Future<RespuestaApi<T>> get<T>(
    String path, {
    required ParserApi<T> parser,
    Map<String, dynamic>? query,
    String? mensajeError,
  }) =>
      _enviar('GET', path,
          parser: parser, query: query, mensajeError: mensajeError);

  Future<RespuestaApi<T>> post<T>(
    String path, {
    Object? body,
    required ParserApi<T> parser,
    String? mensajeError,
  }) =>
      _enviar('POST', path,
          body: body, parser: parser, mensajeError: mensajeError);

  Future<RespuestaApi<T>> put<T>(
    String path, {
    Object? body,
    required ParserApi<T> parser,
    String? mensajeError,
  }) =>
      _enviar('PUT', path,
          body: body, parser: parser, mensajeError: mensajeError);

  Future<RespuestaApi<T>> patch<T>(
    String path, {
    Object? body,
    required ParserApi<T> parser,
    String? mensajeError,
  }) =>
      _enviar('PATCH', path,
          body: body, parser: parser, mensajeError: mensajeError);

  Future<RespuestaApi<T>> delete<T>(
    String path, {
    required ParserApi<T> parser,
    String? mensajeError,
  }) =>
      _enviar('DELETE', path, parser: parser, mensajeError: mensajeError);

  Future<RespuestaApi<T>> _enviar<T>(
    String metodo,
    String path, {
    Object? body,
    required ParserApi<T> parser,
    Map<String, dynamic>? query,
    String? mensajeError,
  }) async {
    final base = Uri.parse('${_entorno.apiUrl}$path');
    final uri = query == null
        ? base
        : base.replace(queryParameters: {
            for (final e in query.entries)
              if (e.value != null) e.key: '${e.value}',
          });
    final solicitud = SolicitudApi(
      metodo: metodo,
      uri: uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    try {
      for (final i in _interceptores) {
        i.antesDeEnviar(solicitud);
      }
    } catch (e, pila) {
      _registro.registrar('ApiClient.interceptor', e, pila);
      throw const ApiException(
        status: -1,
        message: ApiException.mensajePorDefecto,
        code: ApiException.codigoInterceptor,
      );
    }

    final http.Response res;
    try {
      res = await _transmitir(solicitud).timeout(_timeout);
    } on Exception catch (e, pila) {
      // Timeout, ClientException, SocketException and other transport errors.
      _registro.registrar('ApiClient.transporte', e, pila);
      throw const ApiException.sinConexion();
    }

    final texto = utf8.decode(res.bodyBytes, allowMalformed: true);
    final exito = res.statusCode >= 200 && res.statusCode < 300;
    if (!exito) {
      final error = ApiException.desdeJson(
        res.statusCode,
        _decodificarONulo(texto),
        mensajePorDefecto: mensajeError,
      );
      await _notificarError(error, solicitud);
      throw error;
    }

    try {
      final json = _decodificar(texto);
      final mapa = aMapa(json);
      final mensaje = mapa['message'];
      return RespuestaApi<T>(
        mensaje: mensaje is String ? mensaje : '',
        datos: parser(mapa['data']),
      );
    } on ApiException {
      rethrow;
    } catch (e, pila) {
      // FormatException, TypeError, StateError, ArgumentError, RangeError...
      _registro.registrar('ApiClient.respuesta', e, pila);
      throw ApiException(
        status: res.statusCode,
        message: mensajeError ?? ApiException.mensajePorDefecto,
        code: ApiException.codigoRespuestaInvalida,
      );
    }
  }

  /// Runs the error chain; a failing interceptor never masks the real error.
  Future<void> _notificarError(ApiException error, SolicitudApi solicitud) async {
    for (final i in _interceptores) {
      try {
        await i.alRecibirError(error, solicitud);
      } catch (e, pila) {
        _registro.registrar('ApiClient.interceptor', e, pila);
      }
    }
  }

  Future<http.Response> _transmitir(SolicitudApi s) async {
    final req = http.Request(s.metodo, s.uri)..headers.addAll(s.headers);
    if (s.body != null) req.body = jsonEncode(s.body);
    return http.Response.fromStream(await _cliente.send(req));
  }

  /// Error bodies may be HTML or empty; never throw from them.
  Object? _decodificarONulo(String texto) {
    try {
      return _decodificar(texto);
    } on FormatException {
      return null;
    }
  }

  /// Decodes JSON; empty text yields null, malformed text throws FormatException.
  Object? _decodificar(String texto) {
    if (texto.trim().isEmpty) return null;
    return jsonDecode(texto);
  }
}
