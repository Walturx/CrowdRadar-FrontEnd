import '../../../core/models/validacion.dart';
import '../../../core/network/respuesta_api.dart';

/// Frozen contract (M5). Failures are thrown as `ApiException`
/// (422 `AUTOVALIDACION_NO_PERMITIDA`, 409 `VALIDACION_DUPLICADA`, ...).
abstract class ValidacionRepository {
  /// `GET /api/validaciones/pendientes`.
  Future<Pagina<ReportePendiente>> pendientes({
    double? lat,
    double? lng,
    double radioKm = 5,
    int horas = 3,
    int page = 1,
    int size = 20,
  });

  /// `GET /api/reportes/:id`.
  Future<DetalleReporte> obtenerReporte(int reporteId);

  /// `POST /api/reportes/:id/validaciones`.
  Future<void> validar(int reporteId, TipoAccionValidacion accion);

  /// `GET /api/reportes/mios/validacion`.
  Future<List<EstadoReporteValidacion>> estadoMisReportes();

  /// `POST /api/reportes/:id/denuncias`; [detalle] is required for `otro`.
  Future<void> denunciar(
    int reporteId,
    MotivoDenuncia motivo, {
    String? detalle,
  });
}
