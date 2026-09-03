import '../../../core/models/nivel_saturacion.dart';
import '../../../core/models/reporte_saturacion.dart';
import '../../../core/network/respuesta_api.dart';

/// Frozen contract (M4). Failures are thrown as `ApiException`
/// (e.g. 422 `REPORTE_EN_ESPERA`).
abstract class ReporteRepository {
  /// `POST /api/reportes`.
  Future<ReporteCreado> reportar(int lugarId, NivelSaturacion nivel);

  /// `GET /api/reportes/mios`.
  Future<Pagina<ReporteSaturacion>> listarMios({int page = 1, int size = 20});
}
