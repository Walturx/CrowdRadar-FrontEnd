import '../network/api_exception.dart';

const String mensajeGenerico = 'Ocurrió un error inesperado';

/// User-facing text: the API message, else a generic one (never `toString()`).
String mensajeDeError(Object error) =>
    error is ApiException ? error.message : mensajeGenerico;

/// True when the failure is a network problem worth a retry affordance.
bool esErrorSinConexion(Object error) =>
    error is ApiException && error.esSinConexion;

/// Backend error code, when there is one.
String? codigoDeError(Object error) => error is ApiException ? error.code : null;

/// Field errors of a validation failure as `campo -> mensaje`.
Map<String, String> erroresPorCampo(Object error) => error is ApiException
    ? {for (final e in error.errors) e.campo: e.mensaje}
    : const {};
