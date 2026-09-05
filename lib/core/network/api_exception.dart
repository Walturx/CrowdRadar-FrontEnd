import '../utils/lectura_json.dart';

/// Field-level validation error from the backend envelope.
class ErrorCampo {
  final String campo;
  final String mensaje;

  const ErrorCampo({required this.campo, required this.mensaje});
}

/// Typed failure for every API call.
class ApiException implements Exception {
  static const String mensajePorDefecto = 'Ocurrió un error inesperado';
  static const String mensajeSinConexion =
      'No se pudo conectar con el servidor';

  static const String codigoInterceptor = 'INTERCEPTOR';
  static const String codigoRespuestaInvalida = 'RESPUESTA_INVALIDA';

  final int status;
  final String message;
  final String? code;
  final List<ErrorCampo> errors;

  const ApiException({
    required this.status,
    required this.message,
    this.code,
    this.errors = const [],
  });

  /// Network failure or timeout (no HTTP status).
  const ApiException.sinConexion()
      : status = 0,
        message = mensajeSinConexion,
        code = null,
        errors = const [];

  /// Builds from a decoded error body; tolerant to missing or odd shapes.
  factory ApiException.desdeJson(
    int status,
    Object? json, {
    String? mensajePorDefecto,
  }) {
    final mapa = aMapa(json);
    final message = mapa['message'];
    final code = mapa['code'];
    final errors = mapa['errors'];
    return ApiException(
      status: status,
      message: message is String
          ? message
          : (mensajePorDefecto ?? ApiException.mensajePorDefecto),
      code: code is String ? code : null,
      errors: errors is List
          ? [
              for (final e in errors)
                if (e is Map<String, dynamic>)
                  ErrorCampo(
                    campo: '${e['campo'] ?? ''}',
                    mensaje: '${e['mensaje'] ?? ''}',
                  ),
            ]
          : const [],
    );
  }

  bool get esSinConexion => status == 0;

  @override
  String toString() => 'ApiException($status, $message)';
}
