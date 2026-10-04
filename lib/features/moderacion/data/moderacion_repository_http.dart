import '../../../core/network/api_client.dart';
import '../../../core/network/repositorio_no_implementado.dart';
import 'moderacion_repository.dart';

/// Stub owned by M6: replace the mixin with real calls through [_api].
class ModeracionRepositoryHttp
    with RepositorioNoImplementado
    implements ModeracionRepository {
  // ignore: unused_field
  final ApiClient _api;

  ModeracionRepositoryHttp(this._api);
}
