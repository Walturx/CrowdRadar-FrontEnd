import '../../../core/models/usuario.dart';

/// Profile of the authenticated user. Failures are thrown as `ApiException`.
abstract class PerfilRepository {
  Future<Usuario> obtener();

  /// Partial update; also refreshes the session user.
  Future<Usuario> actualizar(Map<String, dynamic> cambios);

  Future<void> cambiarPassword({
    required String actual,
    required String nueva,
    required String confirmar,
  });
}
