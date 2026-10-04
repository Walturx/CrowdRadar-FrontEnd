import 'interceptor_api.dart';

/// Interceptor strategy: adds `Authorization: Bearer <token>` when a session token exists.
class AuthInterceptor extends InterceptorApi {
  final String? Function() _leerToken;

  AuthInterceptor(this._leerToken);

  @override
  void antesDeEnviar(SolicitudApi solicitud) {
    final token = _leerToken();
    if (token != null) {
      solicitud.headers['Authorization'] = 'Bearer $token';
    }
  }
}
