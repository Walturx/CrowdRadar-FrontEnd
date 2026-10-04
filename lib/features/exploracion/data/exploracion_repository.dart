import '../../../core/models/lugar_resumen.dart';
import '../../../core/network/respuesta_api.dart';
import 'categoria_resumen.dart';
import 'filtro_exploracion.dart';

/// Contract (M3). Failures are thrown as `ApiException`.
abstract class ExploracionRepository {
  /// `GET /api/lugares/explorar`; an empty result carries the server message.
  /// Reserved for the M3 explore screen (not wired to the UI yet: the map
  /// filters use `/api/lugares` through `LugarRepository.buscar`).
  Future<ResultadoLista<LugarResumen>> explorar(FiltroExploracion filtro);

  /// `GET /api/lugares/categorias`: every category, with its place count.
  Future<List<CategoriaResumen>> listarCategorias();
}
