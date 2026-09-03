import '../../../core/network/api_client.dart';
import '../../../core/network/repositorio_no_implementado.dart';
import 'analitica_repository.dart';

/// Stub owned by M4: replace the mixin with real calls through [_api].
class AnaliticaRepositoryHttp
    with RepositorioNoImplementado
    implements AnaliticaRepository {
  // ignore: unused_field
  final ApiClient _api;

  AnaliticaRepositoryHttp(this._api);
}
