import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/entorno.dart';
import 'api_exception.dart';
import 'interceptores/interceptor_api.dart';
import 'respuesta_api.dart';

typedef ParserApi<T> = T Function(Object? datos);

/// Single HTTP entry point: JSON, 15 s timeout, typed envelope, interceptors.
class ApiClient {
  static const Duration timeoutPorDefecto = Duration(seconds: 15);

  final http.Client _cliente;
  final Entorno _entorno;
  final List<InterceptorApi> _interceptores;
  final Duration _timeout;

  ApiClient(
    this._cliente,
    this._entorno, {
    List<InterceptorApi> interceptores = const [],
    Duration timeout = timeoutPorDefecto,
  })  : _interceptores = interceptores,
        _timeout = timeout;

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
    for (final i in _interceptores) {
      i.antesDeEnviar(solicitud);
    }

    final http.Response res;
    try {
      res = await _transmitir(solicitud).timeout(_timeout);
    } on TimeoutException {
      throw const ApiException.sinConexion();
    } on http.ClientException {
      throw const ApiException.sinConexion();
    } on Exception {
      // SocketException and other transport failures
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
      for (final i in _interceptores) {
        i.alRecibirError(error, solicitud);
      }
      throw error;
    }

    try {
      final json = _decodificar(texto);
      final mapa = json is Map<String, dynamic> ? json : const <String, dynamic>{};
      final mensaje = mapa['message'];
      return RespuestaApi<T>(
        mensaje: mensaje is String ? mensaje : '',
        datos: parser(mapa['data']),
      );
    } on FormatException {
      throw ApiException(
        status: res.statusCode,
        message: mensajeError ?? ApiException.mensajePorDefecto,
      );
    } on TypeError {
      throw ApiException(
        status: res.statusCode,
        message: mensajeError ?? ApiException.mensajePorDefecto,
      );
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
