import '../../../core/models/moderacion.dart';
import '../../../core/network/respuesta_api.dart';

/// Frozen contract (M6, admin only). Failures are thrown as `ApiException`
/// (409 `USUARIO_YA_SUSPENDIDO`, `USUARIO_NO_SUSPENDIDO`, ...).
abstract class ModeracionRepository {
  /// `GET /api/admin/reportes-denunciados`.
  Future<Pagina<ReporteDenunciado>> reportesDenunciados({
    int page = 1,
    int size = 20,
  });

  /// `GET /api/admin/reportes-denunciados/:reporteId`.
  Future<ReporteDenunciado> reporteDenunciado(int reporteId);

  /// `POST /api/admin/reportes-denunciados/:reporteId/resolucion`.
  Future<void> resolver(
    int reporteId,
    DecisionModeracion decision, {
    String? comentario,
  });

  /// `GET /api/admin/usuarios`.
  Future<Pagina<UsuarioAdmin>> usuarios({
    String? q,
    String? status,
    String? orden,
    int page = 1,
    int size = 20,
  });

  /// `GET /api/admin/usuarios/:id`.
  Future<UsuarioAdmin> usuario(int usuarioId);

  /// `POST /api/admin/usuarios/:id/suspension`; [dias] is 3, 7 or 30.
  Future<void> suspender(
    int usuarioId, {
    required int dias,
    required String motivo,
  });

  /// `POST /api/admin/usuarios/:id/reactivacion`.
  Future<void> reactivar(int usuarioId);
}
