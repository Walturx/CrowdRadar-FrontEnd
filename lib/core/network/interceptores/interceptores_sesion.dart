import '../../logging/registro_errores.dart';
import '../../session/session_service.dart';
import 'auth_interceptor.dart';
import 'interceptor_api.dart';
import 'sesion_expirada_interceptor.dart';

/// Default interceptor chain bound to the session.
List<InterceptorApi> interceptoresDeSesion(
  SessionService sesion, {
  RegistroErrores registro = const RegistroErroresConsola(),
}) =>
    [
      AuthInterceptor(() => sesion.token),
      SesionExpiradaInterceptor(sesion.expirar, registro: registro),
    ];
