import '../../../core/models/enum_api.dart';
import '../../../core/models/moderacion.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/respuesta_api.dart';
import '../../../core/utils/lectura_json.dart';
import 'moderacion_repository.dart';

/// Repository pattern: HTTP implementation of the [ModeracionRepository] port.
class ModeracionRepositoryHttp implements ModeracionRepository {
  static const String rutaReportes = '/api/admin/reportes-denunciados';
  static const String rutaUsuarios = '/api/admin/usuarios';

  final ApiClient _api;

  ModeracionRepositoryHttp(this._api);

  @override
  Future<Pagina<ReporteDenunciado>> reportesDenunciados({
    int page = 1,
    int size = 20,
  }) async {
    final res = await _api.get<Pagina<ReporteDenunciado>>(
      rutaReportes,
      query: {'page': page, 'size': size},
      mensajeError: 'No se pudieron obtener los reportes denunciados',
      parser: (d) =>
          Pagina.fromJson(d, (i) => ReporteDenunciado.fromJson(aMapa(i))),
    );
    return res.datos;
  }

  @override
  Future<DetalleReporteDenunciado> reporteDenunciado(int reporteId) async {
    final res = await _api.get<DetalleReporteDenunciado>(
      '$rutaReportes/$reporteId',
      mensajeError: 'No se pudo obtener el reporte denunciado',
      parser: (d) => DetalleReporteDenunciado.fromJson(aMapa(d)),
    );
    return res.datos;
  }

  @override
  Future<ResolucionReporte> resolver(
    int reporteId,
    DecisionModeracion decision, {
    String? comentario,
  }) async {
    final texto = comentario?.trim();
    final res = await _api.post<ResolucionReporte>(
      '$rutaReportes/$reporteId/resolucion',
      body: {
        'decision': decision.valorApi,
        if (texto != null && texto.isNotEmpty) 'comentario': texto,
      },
      mensajeError: 'No se pudo registrar la decisión',
      parser: (d) => ResolucionReporte.fromJson(aMapa(d)),
    );
    return res.datos;
  }

  @override
  Future<Pagina<UsuarioAdmin>> usuarios({
    String? q,
    EstadoCuenta? status,
    OrdenUsuarios? orden,
    int page = 1,
    int size = 20,
  }) async {
    final res = await _api.get<Pagina<UsuarioAdmin>>(
      rutaUsuarios,
      query: {
        'q': q,
        'status': status == null ? null : valorApi(status),
        'orden': orden?.valorApi,
        'page': page,
        'size': size,
      },
      mensajeError: 'No se pudieron obtener los usuarios',
      parser: (d) => Pagina.fromJson(d, (i) => UsuarioAdmin.fromJson(aMapa(i))),
    );
    return res.datos;
  }

  @override
  Future<DetalleUsuarioAdmin> usuario(int usuarioId) async {
    final res = await _api.get<DetalleUsuarioAdmin>(
      '$rutaUsuarios/$usuarioId',
      mensajeError: 'No se pudo obtener el usuario',
      parser: (d) => DetalleUsuarioAdmin.fromJson(aMapa(d)),
    );
    return res.datos;
  }

  @override
  Future<SancionVigente> suspender(
    int usuarioId, {
    required int dias,
    required String motivo,
  }) async {
    final res = await _api.post<SancionVigente>(
      '$rutaUsuarios/$usuarioId/suspension',
      body: {'dias': dias, 'motivo': motivo.trim()},
      mensajeError: 'No se pudo suspender al usuario',
      parser: (d) => SancionVigente.fromJson(aMapa(d)),
    );
    return res.datos;
  }

  @override
  Future<void> reactivar(int usuarioId) async {
    await _api.post<void>(
      '$rutaUsuarios/$usuarioId/reactivacion',
      mensajeError: 'No se pudo reactivar al usuario',
      parser: (_) {},
    );
  }
}
