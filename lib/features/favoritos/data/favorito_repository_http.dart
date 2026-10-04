import '../../../core/network/api_client.dart';
import '../../../core/network/repositorio_no_implementado.dart';
import 'favorito_repository.dart';

/// Repository pattern: HTTP implementation of the [FavoritoRepository] port (stub owned by M3).
///
/// Replace the `RepositorioNoImplementado` mixin with real calls through [_api].
class FavoritoRepositoryHttp
    with RepositorioNoImplementado
    implements FavoritoRepository {
  // ignore: unused_field
  final ApiClient _api;

  FavoritoRepositoryHttp(this._api);
}
