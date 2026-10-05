import '../../../core/models/validacion.dart';
import '../../../core/network/respuesta_api.dart';

/// Failures are thrown as `ApiException` (404 `REPORTE_NO_ENCONTRADO`,
/// 422 `AUTOVALIDACION_NO_PERMITIDA` / `AUTODENUNCIA_NO_PERMITIDA`,
/// 409 `VALIDACION_DUPLICADA` / `DENUNCIA_DUPLICADA`).
abstract class ValidacionRepository {
  /// `GET /api/validaciones/pendientes`.
  Future<Pagina<ReportePendiente>> pendientes({
    required double lat,
    required double lng,
    double radioKm = 5,
    int horas = 3,
    int page = 1,
    int size = 20,
  });

  /// `GET /api/reportes/:id`.
  Future<DetalleReporte> obtenerReporte(int reporteId);

  /// `GET /api/reportes/:id/confiabilidad`: only the reliability block.
  Future<Confiabilidad> confiabilidad(int reporteId);

  /// `POST /api/reportes/:id/validaciones`.
  Future<ResultadoVoto> validar(int reporteId, TipoAccionValidacion accion);

  /// `GET /api/reportes/mios/validacion`, newest first.
  Future<Pagina<EstadoReporteValidacion>> estadoMisReportes({
    int page = 1,
    int size = 20,
  });

  /// `POST /api/reportes/:id/denuncias`; [detalle] is required for `otro`.
  Future<void> denunciar(
    int reporteId,
    MotivoDenuncia motivo, {
    String? detalle,
  });
}
