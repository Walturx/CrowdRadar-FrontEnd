import '../../../core/network/api_client.dart';
import '../../../core/network/repositorio_no_implementado.dart';
import 'reporte_repository.dart';

/// Repository pattern: HTTP implementation of the [ReporteRepository] port (stub owned by M4).
///
/// Replace the `RepositorioNoImplementado` mixin with real calls through [_api].
class ReporteRepositoryHttp
    with RepositorioNoImplementado
    implements ReporteRepository {
  // ignore: unused_field
  final ApiClient _api;

  ReporteRepositoryHttp(this._api);
}
