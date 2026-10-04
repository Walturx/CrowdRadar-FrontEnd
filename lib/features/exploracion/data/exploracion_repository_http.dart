import '../../../core/models/enum_api.dart';
import '../../../core/models/lugar_resumen.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/respuesta_api.dart';
import '../../../core/utils/lectura_json.dart';
import 'categoria_resumen.dart';
import 'exploracion_repository.dart';
import 'filtro_exploracion.dart';

/// Repository pattern: HTTP implementation of the [ExploracionRepository] port.
class ExploracionRepositoryHttp implements ExploracionRepository {
  static const String rutaExplorar = '/api/lugares/explorar';
  static const String rutaCategorias = '/api/lugares/categorias';

  final ApiClient _api;

  ExploracionRepositoryHttp(this._api);

  @override
  Future<ResultadoLista<LugarResumen>> explorar(
    FiltroExploracion filtro,
  ) async {
    final categoria = filtro.categoria;
    final saturacion = filtro.saturacion;
    final res = await _api.get<List<LugarResumen>>(
      rutaExplorar,
      query: {
        'categoria': categoria == null ? null : valorApi(categoria),
        'saturacion': saturacion == null ? null : valorApi(saturacion),
        'lat': filtro.lat,
        'lng': filtro.lng,
        'radioKm': filtro.radioKm,
      },
      mensajeError: 'No pudimos explorar los lugares',
      parser: (d) => [
        for (final i in aLista(aMapa(d)['items']))
          LugarResumen.fromJson(aMapa(i)),
      ],
    );
    return ResultadoLista(mensaje: res.mensaje, items: res.datos);
  }

  @override
  Future<List<CategoriaResumen>> listarCategorias() async {
    final res = await _api.get<List<CategoriaResumen>>(
      rutaCategorias,
      mensajeError: 'No pudimos obtener las categorías',
      parser: (d) => [
        for (final i in aLista(aMapa(d)['items']))
          CategoriaResumen.fromJson(aMapa(i)),
      ],
    );
    return res.datos;
  }
}
