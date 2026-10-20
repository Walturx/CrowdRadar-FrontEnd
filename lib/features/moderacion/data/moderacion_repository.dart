import '../../../core/models/moderacion.dart';
import '../../../core/network/respuesta_api.dart';

/// Frozen contract (M6, admin only). Failures are thrown as `ApiException`
/// (403 non-admin, 409 `USUARIO_YA_SUSPENDIDO` / `USUARIO_NO_SUSPENDIDO` /
/// `SIN_DENUNCIAS_PENDIENTES`, 422 `OPERACION_NO_PERMITIDA`, 404, 400).
abstract class ModeracionRepository {
  /// `GET /api/admin/reportes-denunciados`: reports with pending denuncias.
  Future<Pagina<ReporteDenunciado>> reportesDenunciados({
    int page = 1,
    int size = 20,
  });

  /// `GET /api/admin/reportes-denunciados/:reporteId`.
  Future<DetalleReporteDenunciado> reporteDenunciado(int reporteId);

  /// `POST /api/admin/reportes-denunciados/:reporteId/resolucion`.
  Future<ResolucionReporte> resolver(
    int reporteId,
    DecisionModeracion decision, {
    String? comentario,
  });

  /// `GET /api/admin/usuarios`; [q] must have 2 to 80 characters.
  Future<Pagina<UsuarioAdmin>> usuarios({
    String? q,
    EstadoCuenta? status,
    OrdenUsuarios? orden,
    int page = 1,
    int size = 20,
  });

  /// `GET /api/admin/usuarios/:id`.
  Future<DetalleUsuarioAdmin> usuario(int usuarioId);

  /// `POST /api/admin/usuarios/:id/suspension`; [dias] is 3, 7 or 30 and
  /// [motivo] has 10 to 280 characters.
  Future<SancionVigente> suspender(
    int usuarioId, {
    required int dias,
    required String motivo,
  });

  /// `POST /api/admin/usuarios/:id/reactivacion`.
  Future<void> reactivar(int usuarioId);
}
