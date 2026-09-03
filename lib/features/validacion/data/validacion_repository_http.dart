import '../../../core/network/api_client.dart';
import '../../../core/network/repositorio_no_implementado.dart';
import 'validacion_repository.dart';

/// Stub owned by M5: replace the mixin with real calls through [_api].
class ValidacionRepositoryHttp
    with RepositorioNoImplementado
    implements ValidacionRepository {
  // ignore: unused_field
  final ApiClient _api;

  ValidacionRepositoryHttp(this._api);
}
