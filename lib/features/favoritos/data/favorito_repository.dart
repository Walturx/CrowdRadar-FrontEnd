import '../../../core/models/favorito.dart';
import '../../../core/network/respuesta_api.dart';

/// Frozen contract (M3). Failures are thrown as `ApiException`
/// (409 `FAVORITO_DUPLICADO`, 404 `FAVORITO_NO_ENCONTRADO`, ...).
abstract class FavoritoRepository {
  /// `GET /api/favoritos`; an empty list carries the explanatory message.
  Future<ResultadoLista<Favorito>> listar();

  /// `POST /api/favoritos`.
  Future<void> agregar(int lugarId);

  /// `DELETE /api/favoritos/:lugarId`.
  Future<void> eliminar(int lugarId);

  /// `PATCH /api/favoritos/:lugarId/alertas`.
  Future<void> configurarAlertas(int lugarId, {required bool activadas});
}
