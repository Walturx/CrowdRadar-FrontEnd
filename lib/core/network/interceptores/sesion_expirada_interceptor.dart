import '../../logging/registro_errores.dart';
import '../../session/motivo_cierre.dart';
import '../api_exception.dart';
import 'interceptor_api.dart';

/// Interceptor strategy: ends the session on 401 or CUENTA_SUSPENDIDA outside `/api/auth/`.
class SesionExpiradaInterceptor extends InterceptorApi {
  static const String _prefijoAuth = '/api/auth/';
  static const String _codigoSuspendida = 'CUENTA_SUSPENDIDA';

  final Future<void> Function(MotivoCierre motivo) _alExpirar;
  final RegistroErrores _registro;

  SesionExpiradaInterceptor(
    this._alExpirar, {
    RegistroErrores registro = const RegistroErroresConsola(),
  }) : _registro = registro;

  @override
  Future<void> alRecibirError(ApiException error, SolicitudApi solicitud) async {
    if (solicitud.uri.path.startsWith(_prefijoAuth)) return;
    final MotivoCierre motivo;
    if (error.code == _codigoSuspendida) {
      motivo = MotivoCierre.cuentaSuspendida;
    } else if (error.status == 401) {
      motivo = MotivoCierre.sesionExpirada;
    } else {
      return;
    }
    try {
      await _alExpirar(motivo);
    } catch (e, pila) {
      // The original API error must reach the caller even if closing fails.
      _registro.registrar('SesionExpiradaInterceptor', e, pila);
    }
  }
}
