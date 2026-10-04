import '../network/api_exception.dart';

const int segundosPorMinuto = 60;

/// Rate-limit subject for user actions (votes, reports).
const String sujetoAcciones = 'Demasiadas acciones seguidas';

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
///
/// [sujeto] is the message subject ("Demasiados intentos" by default).
String mensajeEspera(int? segundos, {String sujeto = 'Demasiados intentos'}) {
  if (segundos == null || segundos <= 0) {
    return '$sujeto, probá más tarde';
  }
  final minutos = (segundos / segundosPorMinuto).ceil();
  return '$sujeto, probá en $minutos '
      '${minutos == 1 ? 'minuto' : 'minutos'}';
}
