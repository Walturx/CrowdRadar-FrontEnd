import '../../../core/network/api_client.dart';
import '../../../core/network/repositorio_no_implementado.dart';
import 'lugar_repository.dart';

/// Stub owned by M2: replace the mixin with real calls through [_api].
class LugarRepositoryHttp
    with RepositorioNoImplementado
    implements LugarRepository {
  // ignore: unused_field
  final ApiClient _api;

  LugarRepositoryHttp(this._api);
}
