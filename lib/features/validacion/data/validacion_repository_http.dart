import '../../../core/models/enum_api.dart';
import '../../../core/models/validacion.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/respuesta_api.dart';
import '../../../core/utils/lectura_json.dart';
import 'validacion_repository.dart';

/// Repository pattern: HTTP implementation of the [ValidacionRepository] port.
class ValidacionRepositoryHttp implements ValidacionRepository {
  static const String rutaReportes = '/api/reportes';

  final ApiClient _api;

  ValidacionRepositoryHttp(this._api);

  @override
  Future<Pagina<ReportePendiente>> pendientes({
    required double lat,
    required double lng,
    double radioKm = 5,
    int horas = 3,
    int page = 1,
    int size = 20,
  }) async {
    final res = await _api.get<Pagina<ReportePendiente>>(
      '/api/validaciones/pendientes',
      query: {
        'lat': lat,
        'lng': lng,
        'radioKm': radioKm,
        'horas': horas,
        'page': page,
        'size': size,
      },
      mensajeError: 'No se pudieron obtener los reportes por validar',
      parser: (d) =>
          Pagina.fromJson(d, (i) => ReportePendiente.fromJson(aMapa(i))),
    );
    return res.datos;
  }

  @override
  Future<DetalleReporte> obtenerReporte(int reporteId) async {
    final res = await _api.get<DetalleReporte>(
      '$rutaReportes/$reporteId',
      mensajeError: 'No se pudo obtener el reporte',
      parser: (d) => DetalleReporte.fromJson(aMapa(d)),
    );
    return res.datos;
  }

  @override
  Future<Confiabilidad> confiabilidad(int reporteId) async {
    final res = await _api.get<Confiabilidad>(
      '$rutaReportes/$reporteId/confiabilidad',
      mensajeError: 'No se pudo obtener la confiabilidad',
      parser: (d) => Confiabilidad.fromJson(aMapa(d)),
    );
    return res.datos;
  }

  @override
  Future<ResultadoVoto> validar(
    int reporteId,
    TipoAccionValidacion accion,
  ) async {
    final res = await _api.post<ResultadoVoto>(
      '$rutaReportes/$reporteId/validaciones',
      body: {'tipoAccion': valorApi(accion)},
      mensajeError: 'No se pudo registrar tu validación',
      parser: (d) => ResultadoVoto.fromJson(aMapa(d)),
    );
    return res.datos;
  }

  @override
  Future<Pagina<EstadoReporteValidacion>> estadoMisReportes({
    int page = 1,
    int size = 20,
  }) async {
    final res = await _api.get<Pagina<EstadoReporteValidacion>>(
      '$rutaReportes/mios/validacion',
      query: {'page': page, 'size': size},
      mensajeError: 'No se pudo obtener el estado de tus reportes',
      parser: (d) => Pagina.fromJson(
        d,
        (i) => EstadoReporteValidacion.fromJson(aMapa(i)),
      ),
    );
    return res.datos;
  }

  @override
  Future<void> denunciar(
    int reporteId,
    MotivoDenuncia motivo, {
    String? detalle,
  }) async {
    final texto = detalle?.trim();
    await _api.post<void>(
      '$rutaReportes/$reporteId/denuncias',
      body: {
        'motivo': valorApi(motivo),
        if (texto != null && texto.isNotEmpty) 'detalle': texto,
      },
      mensajeError: 'No se pudo enviar la denuncia',
      parser: (_) {},
    );
  }
}
