import '../../../core/network/api_client.dart';
import '../../../core/network/repositorio_no_implementado.dart';
import 'analitica_repository.dart';

/// Repository pattern: HTTP implementation of the [AnaliticaRepository] port (stub owned by M4).
///
/// Replace the `RepositorioNoImplementado` mixin with real calls through [_api].
class AnaliticaRepositoryHttp
    with RepositorioNoImplementado
    implements AnaliticaRepository {
  // ignore: unused_field
  final ApiClient _api;

  AnaliticaRepositoryHttp(this._api);
}
