import 'package:crowdradar/core/network/api_client.dart';
import 'package:crowdradar/core/session/session_service.dart';
import 'package:crowdradar/app/fabrica_repositorios.dart';
import 'alerta_repository_fake.dart';
import 'analitica_repository_fake.dart';
import 'auth_repository_fake.dart';
import 'comportamiento_fake.dart';
import 'exploracion_repository_fake.dart';
import 'favorito_repository_fake.dart';
import 'lugar_repository_fake.dart';
import 'moderacion_repository_fake.dart';
import 'perfil_repository_fake.dart';
import 'reporte_repository_fake.dart';
import 'validacion_repository_fake.dart';

/// In-memory [FabricaRepositorios]: every repository is its `*RepositoryFake`
/// over the seed data, all sharing one [comportamiento]. The API client is
/// never used.
class FabricaRepositoriosFake implements FabricaRepositorios {
  final ComportamientoFake comportamiento;

  const FabricaRepositoriosFake({
    this.comportamiento = const ComportamientoFake(),
  });

  @override
  Repositorios crear(ApiClient api, SessionService sesion) => (
    auth: AuthRepositoryFake(sesion, comportamiento: comportamiento),
    perfil: PerfilRepositoryFake(sesion, comportamiento: comportamiento),
    lugar: LugarRepositoryFake(comportamiento: comportamiento),
    reporte: ReporteRepositoryFake(
      comportamiento: comportamiento,
      sesion: sesion,
    ),
    analitica: AnaliticaRepositoryFake(comportamiento: comportamiento),
    validacion: ValidacionRepositoryFake(
      comportamiento: comportamiento,
      sesion: sesion,
    ),
    favorito: FavoritoRepositoryFake(
      comportamiento: comportamiento,
      sesion: sesion,
    ),
    alerta: AlertaRepositoryFake(
      comportamiento: comportamiento,
      sesion: sesion,
    ),
    exploracion: ExploracionRepositoryFake(
      comportamiento: comportamiento,
      sesion: sesion,
    ),
    moderacion: ModeracionRepositoryFake(
      comportamiento: comportamiento,
      sesion: sesion,
    ),
  );
}
