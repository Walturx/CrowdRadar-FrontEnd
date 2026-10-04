import '../../../core/models/user_model.dart';

/// Profile of the authenticated user. Failures are thrown as `ApiException`.
abstract class PerfilRepository {
  Future<UserModel> obtener();

  /// Partial update; also refreshes the session user.
  Future<UserModel> actualizar(Map<String, dynamic> cambios);

  Future<void> cambiarPassword({
    required String actual,
    required String nueva,
    required String confirmar,
  });
}
