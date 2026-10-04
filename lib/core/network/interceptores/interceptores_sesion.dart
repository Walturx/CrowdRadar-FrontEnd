import '../../session/session_service.dart';
import 'auth_interceptor.dart';
import 'interceptor_api.dart';
import 'sesion_expirada_interceptor.dart';

/// Default interceptor chain bound to the session.
List<InterceptorApi> interceptoresDeSesion(SessionService sesion) => [
      AuthInterceptor(() => sesion.token),
      SesionExpiradaInterceptor(sesion.expirar),
    ];
