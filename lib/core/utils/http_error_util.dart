import '../network/api_exception.dart';

/// User-facing text for any failure: the API message, else the raw error.
String mensajeDeError(Object error) =>
    error is ApiException ? error.message : error.toString();

/// Field errors of a validation failure as `campo -> mensaje`.
Map<String, String> erroresPorCampo(Object error) => error is ApiException
    ? {for (final e in error.errors) e.campo: e.mensaje}
    : const {};
