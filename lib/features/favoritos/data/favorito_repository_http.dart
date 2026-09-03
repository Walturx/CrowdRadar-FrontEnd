import '../../../core/network/api_client.dart';
import '../../../core/network/repositorio_no_implementado.dart';
import 'favorito_repository.dart';

/// Stub owned by M3: replace the mixin with real calls through [_api].
class FavoritoRepositoryHttp
    with RepositorioNoImplementado
    implements FavoritoRepository {
  // ignore: unused_field
  final ApiClient _api;

  FavoritoRepositoryHttp(this._api);
}
