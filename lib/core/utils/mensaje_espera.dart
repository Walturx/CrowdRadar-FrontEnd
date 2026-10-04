import '../network/api_exception.dart';

const int segundosPorMinuto = 60;

const _codigosLimite = {'DEMASIADOS_INTENTOS', 'DEMASIADAS_SOLICITUDES'};

/// True when the server rejected the call for rate limiting.
bool esLimiteDeIntentos(Object error) =>
    error is ApiException &&
    (error.status == 429 || _codigosLimite.contains(error.code));

/// Seconds to wait before retrying, only for a rate limit.
int? esperaDeError(Object error) => esLimiteDeIntentos(error)
    ? (error as ApiException).reintentarEnSegundos
    : null;

/// Wait text for a rate limit: whole minutes rounded up, or a generic one
/// when the server did not say how long.
String mensajeEspera(int? segundos) {
  if (segundos == null || segundos <= 0) {
    return 'Demasiados intentos, probá más tarde';
  }
  final minutos = (segundos / segundosPorMinuto).ceil();
  return 'Demasiados intentos, probá en $minutos '
      '${minutos == 1 ? 'minuto' : 'minutos'}';
}
