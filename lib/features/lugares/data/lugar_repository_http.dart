import '../../../core/map/tipos_mapa.dart';
import '../../../core/models/categoria_lugar.dart';
import '../../../core/models/enum_api.dart';
import '../../../core/models/lugar_detalle.dart';
import '../../../core/models/lugar_resumen.dart';
import '../../../core/models/nivel_saturacion.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/respuesta_api.dart';
import '../../../core/utils/lectura_json.dart';
import 'lugar_repository.dart';

/// Repository pattern: HTTP implementation of the [LugarRepository] port.
class LugarRepositoryHttp implements LugarRepository {
  static const String rutaLugares = '/api/lugares';

  final ApiClient _api;

  LugarRepositoryHttp(this._api);

  @override
  Future<ResultadoLista<LugarResumen>> buscar({
    String? q,
    LimitesMapa? bbox,
    CategoriaLugar? categoria,
    NivelSaturacion? nivel,
    int? limite,
  }) async {
    final res = await _api.get<List<LugarResumen>>(
      rutaLugares,
      query: {
        'q': q,
        'bbox': bbox == null ? null : formatoBbox(bbox),
        'categoria': categoria == null ? null : valorApi(categoria),
        'nivel': nivel == null ? null : valorApi(nivel),
        'limite': limite,
      },
      mensajeError: 'Error al obtener los lugares',
      parser: (d) => [
        for (final i in aMapa(d)['items'] as List? ?? const [])
          LugarResumen.fromJson(aMapa(i)),
      ],
    );
    return ResultadoLista(mensaje: res.mensaje, items: res.datos);
  }

  @override
  Future<LugarDetalle> obtener(int id) async {
    final res = await _api.get<LugarDetalle>(
      '$rutaLugares/$id',
      mensajeError: 'Error al obtener el lugar',
      parser: (d) => LugarDetalle.fromJson(aMapa(d)),
    );
    return res.datos;
  }

  /// Wire format of the visible area: `minLng,minLat,maxLng,maxLat`.
  static String formatoBbox(LimitesMapa b) =>
      '${b.oeste},${b.sur},${b.este},${b.norte}';
}
