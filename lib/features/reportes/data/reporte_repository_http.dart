import '../../../core/network/api_client.dart';
import '../../../core/network/repositorio_no_implementado.dart';
import 'reporte_repository.dart';

/// Stub owned by M4: replace the mixin with real calls through [_api].
class ReporteRepositoryHttp
    with RepositorioNoImplementado
    implements ReporteRepository {
  // ignore: unused_field
  final ApiClient _api;

  ReporteRepositoryHttp(this._api);
}
