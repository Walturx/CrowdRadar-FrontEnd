import '../../../core/map/tipos_mapa.dart';
import '../../../core/models/lugar_detalle.dart';
import '../../../core/models/lugar_resumen.dart';
import '../../../core/network/respuesta_api.dart';

/// Frozen contract (M2). Failures are thrown as `ApiException`.
abstract class LugarRepository {
  /// `GET /api/lugares` by text and/or bounding box.
  Future<ResultadoLista<LugarResumen>> buscar({
    String? consulta,
    LimitesMapa? limites,
  });

  /// `GET /api/lugares/:id`.
  Future<LugarDetalle> obtenerDetalle(int lugarId);
}
