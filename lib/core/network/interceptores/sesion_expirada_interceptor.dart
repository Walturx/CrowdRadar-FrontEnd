import '../../session/motivo_cierre.dart';
import '../api_exception.dart';
import 'interceptor_api.dart';

/// Ends the session on 401 or CUENTA_SUSPENDIDA outside `/api/auth/`.
class SesionExpiradaInterceptor extends InterceptorApi {
  static const String _prefijoAuth = '/api/auth/';
  static const String _codigoSuspendida = 'CUENTA_SUSPENDIDA';

  final void Function(MotivoCierre motivo) _alExpirar;

  SesionExpiradaInterceptor(this._alExpirar);

  @override
  void alRecibirError(ApiException error, SolicitudApi solicitud) {
    if (solicitud.uri.path.startsWith(_prefijoAuth)) return;
    if (error.code == _codigoSuspendida) {
      _alExpirar(MotivoCierre.cuentaSuspendida);
    } else if (error.status == 401) {
      _alExpirar(MotivoCierre.sesionExpirada);
    }
  }
}
