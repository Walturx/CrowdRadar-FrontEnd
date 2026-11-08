import '../core/network/api_client.dart';
import '../core/session/session_service.dart';
import '../features/alertas/data/alerta_repository.dart';
import '../features/alertas/data/alerta_repository_http.dart';
import '../features/analitica/data/analitica_repository.dart';
import '../features/analitica/data/analitica_repository_http.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/auth_repository_http.dart';
import '../features/exploracion/data/exploracion_repository.dart';
import '../features/exploracion/data/exploracion_repository_http.dart';
import '../features/favoritos/data/favorito_repository.dart';
import '../features/favoritos/data/favorito_repository_http.dart';
import '../features/lugares/data/lugar_repository.dart';
import '../features/lugares/data/lugar_repository_http.dart';
import '../features/moderacion/data/moderacion_repository.dart';
import '../features/moderacion/data/moderacion_repository_http.dart';
import '../features/perfil/data/perfil_repository.dart';
import '../features/perfil/data/perfil_repository_http.dart';
import '../features/reportes/data/reporte_repository.dart';
import '../features/reportes/data/reporte_repository_http.dart';
import '../features/validacion/data/validacion_repository.dart';
import '../features/validacion/data/validacion_repository_http.dart';

/// One repository per feature: the whole data-access family of the app.
typedef Repositorios = ({
  AuthRepository auth,
  PerfilRepository perfil,
  LugarRepository lugar,
  ReporteRepository reporte,
  AnaliticaRepository analitica,
  ValidacionRepository validacion,
  FavoritoRepository favorito,
  AlertaRepository alerta,
  ExploracionRepository exploracion,
  ModeracionRepository moderacion,
});

/// Abstract Factory pattern: builds the whole [Repositorios] family at once,
/// so the composition root never knows which implementation it got.
///
/// The app only ships [FabricaRepositoriosHttp]; tests inject their own
/// in-memory factory through `Dependencias.crear(repositorios:)`.
abstract class FabricaRepositorios {
  Repositorios crear(ApiClient api, SessionService sesion);
}

/// Repositories backed by the CrowdRadar REST API.
class FabricaRepositoriosHttp implements FabricaRepositorios {
  const FabricaRepositoriosHttp();

  @override
  Repositorios crear(ApiClient api, SessionService sesion) => (
    auth: AuthRepositoryHttp(api, sesion),
    perfil: PerfilRepositoryHttp(api, sesion),
    lugar: LugarRepositoryHttp(api),
    reporte: ReporteRepositoryHttp(api),
    analitica: AnaliticaRepositoryHttp(api),
    validacion: ValidacionRepositoryHttp(api),
    favorito: FavoritoRepositoryHttp(api),
    alerta: AlertaRepositoryHttp(api),
    exploracion: ExploracionRepositoryHttp(api),
    moderacion: ModeracionRepositoryHttp(api),
  );
}
