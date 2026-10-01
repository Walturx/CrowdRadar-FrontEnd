import '../../../core/models/enum_api.dart';
import '../../../core/models/nivel_saturacion.dart';
import '../../../core/models/reporte_saturacion.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/respuesta_api.dart';
import '../../../core/utils/lectura_json.dart';
import 'reporte_repository.dart';

/// Repository pattern: HTTP implementation of the [ReporteRepository] port.
class ReporteRepositoryHttp implements ReporteRepository {
  static const String rutaReportes = '/api/reportes';

  final ApiClient _api;

  ReporteRepositoryHttp(this._api);

  @override
  Future<ReporteCreado> reportar(int lugarId, NivelSaturacion nivel) async {
    final res = await _api.post<ReporteCreado>(
      rutaReportes,
      body: {'lugarId': lugarId, 'nivel': valorApi(nivel)},
      mensajeError: 'No se pudo enviar el reporte',
      parser: (d) => ReporteCreado.fromJson(aMapa(d)),
    );
    return res.datos;
  }

  @override
  Future<Pagina<ReporteSaturacion>> listarMios({
    int page = 1,
    int size = 20,
  }) async {
    final res = await _api.get<Pagina<ReporteSaturacion>>(
      '$rutaReportes/mios',
      query: {'page': page, 'size': size},
      mensajeError: 'No se pudieron obtener tus reportes',
      parser: (d) =>
          Pagina.fromJson(d, (i) => ReporteSaturacion.fromJson(aMapa(i))),
    );
    return res.datos;
  }
}
