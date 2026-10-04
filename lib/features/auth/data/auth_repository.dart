import '../../../core/models/usuario.dart';

/// Account access. Failures are thrown as `ApiException`.
abstract class AuthRepository {
  /// Logs in and starts the session; returns the authenticated user.
  Future<Usuario> iniciarSesion(String email, String password);

  Future<Usuario> registrar({
    required String nombre,
    required String apellido,
    required String email,
    required String password,
    required String telefono,
    required String distrito,
  });

  /// Neutral response by design: never reveals whether the email exists.
  Future<void> solicitarRecuperacion(String email);
}
