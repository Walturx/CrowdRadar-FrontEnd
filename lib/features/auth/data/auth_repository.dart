import '../../../core/models/user_model.dart';

/// Account access. Failures are thrown as `ApiException`.
abstract class AuthRepository {
  /// Logs in and starts the session; returns the authenticated user.
  Future<UserModel> iniciarSesion(String email, String password);

  Future<UserModel> registrar({
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
