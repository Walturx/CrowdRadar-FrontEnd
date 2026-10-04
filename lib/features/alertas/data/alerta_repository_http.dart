import '../../../core/models/alerta.dart';
import '../../../core/models/enum_api.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/respuesta_api.dart';
import '../../../core/utils/lectura_json.dart';
import 'alerta_repository.dart';

/// Repository pattern: HTTP implementation of the [AlertaRepository] port.
class AlertaRepositoryHttp implements AlertaRepository {
  static const String rutaAlertas = '/api/alertas';
  static const String rutaDispositivos = '/api/dispositivos';

  final ApiClient _api;

  AlertaRepositoryHttp(this._api);

  @override
  Future<PaginaAlertas> listar({int page = 1, int size = 20}) async {
    final res = await _api.get<(Pagina<Alerta>, int)>(
      rutaAlertas,
      query: {'page': page, 'size': size},
      mensajeError: 'No pudimos obtener tus alertas',
      parser: (d) => (
        Pagina.fromJson(d, (i) => Alerta.fromJson(aMapa(i))),
        aInt(aMapa(d)['noLeidas']),
      ),
    );
    return PaginaAlertas(
      pagina: res.datos.$1,
      noLeidas: res.datos.$2,
      mensaje: res.mensaje,
    );
  }

  @override
  Future<void> marcarLeida(int id) async {
    await _api.patch<void>(
      '$rutaAlertas/$id/leida',
      mensajeError: 'No pudimos marcar la alerta como leída',
      parser: (_) {},
    );
  }

  @override
  Future<void> registrarDispositivo(
    String token,
    PlataformaPush plataforma,
  ) async {
    await _api.post<void>(
      rutaDispositivos,
      body: {'token': token, 'plataforma': valorApi(plataforma)},
      mensajeError: 'No pudimos registrar el dispositivo',
      parser: (_) {},
    );
  }

  @override
  Future<void> eliminarDispositivo(String token) async {
    await _api.delete<void>(
      '$rutaDispositivos/${Uri.encodeComponent(token)}',
      mensajeError: 'No pudimos quitar el dispositivo',
      parser: (_) {},
    );
  }
}
