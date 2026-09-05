import '../../../core/network/api_client.dart';
import '../../../core/network/repositorio_no_implementado.dart';
import 'lugar_repository.dart';

/// Repository pattern: HTTP implementation of the [LugarRepository] port (stub owned by M2).
///
/// Replace the `RepositorioNoImplementado` mixin with real calls through [_api].
class LugarRepositoryHttp
    with RepositorioNoImplementado
    implements LugarRepository {
  // ignore: unused_field
  final ApiClient _api;

  LugarRepositoryHttp(this._api);
}
