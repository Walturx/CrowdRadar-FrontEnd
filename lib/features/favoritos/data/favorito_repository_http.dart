import '../../../core/models/favorito.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/respuesta_api.dart';
import '../../../core/utils/lectura_json.dart';
import 'favorito_repository.dart';

/// Repository pattern: HTTP implementation of the [FavoritoRepository] port.
class FavoritoRepositoryHttp implements FavoritoRepository {
  static const String rutaFavoritos = '/api/favoritos';

  final ApiClient _api;

  FavoritoRepositoryHttp(this._api);

  @override
  Future<ResultadoLista<Favorito>> listar() async {
    final res = await _api.get<List<Favorito>>(
      rutaFavoritos,
      mensajeError: 'No pudimos obtener tus favoritos',
      parser: (d) => [
        for (final i in aLista(aMapa(d)['items'])) Favorito.fromJson(aMapa(i)),
      ],
    );
    return ResultadoLista(mensaje: res.mensaje, items: res.datos);
  }

  @override
  Future<void> agregar(int lugarId) async {
    await _api.post<void>(
      rutaFavoritos,
      body: {'lugarId': lugarId},
      mensajeError: 'No pudimos añadir el lugar a tus favoritos',
      parser: (_) {},
    );
  }

  @override
  Future<void> eliminar(int lugarId) async {
    await _api.delete<void>(
      '$rutaFavoritos/$lugarId',
      mensajeError: 'No pudimos quitar el lugar de tus favoritos',
      parser: (_) {},
    );
  }

  @override
  Future<void> configurarAlertas(int lugarId, {required bool activadas}) async {
    await _api.patch<void>(
      '$rutaFavoritos/$lugarId/alertas',
      body: {'alertasActivadas': activadas},
      mensajeError: 'No pudimos cambiar las alertas del lugar',
      parser: (_) {},
    );
  }
}
