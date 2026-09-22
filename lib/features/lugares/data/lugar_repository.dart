import '../../../core/map/tipos_mapa.dart';
import '../../../core/models/categoria_lugar.dart';
import '../../../core/models/lugar_detalle.dart';
import '../../../core/models/lugar_resumen.dart';
import '../../../core/models/nivel_saturacion.dart';
import '../../../core/network/respuesta_api.dart';

/// Frozen contract (M2). Failures are thrown as `ApiException`.
abstract class LugarRepository {
  /// `GET /api/lugares`: by text ([q], 2-60 chars) and/or visible area
  /// ([bbox]); at least one of them is required. An empty result carries the
  /// server message in [ResultadoLista.mensaje].
  Future<ResultadoLista<LugarResumen>> buscar({
    String? q,
    LimitesMapa? bbox,
    CategoriaLugar? categoria,
    NivelSaturacion? nivel,
    int? limite,
  });

  /// `GET /api/lugares/:id`; 404 `LUGAR_NO_ENCONTRADO` when it does not exist.
  Future<LugarDetalle> obtener(int id);
}
