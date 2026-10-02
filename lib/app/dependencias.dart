import 'package:flutter/foundation.dart';

import '../core/config/entorno.dart';
import '../core/map/flutter_map_adapter.dart';
import '../core/map/mapa_adapter.dart';
import '../core/network/api_client.dart';
import '../core/network/cliente_http_factory.dart';
import '../core/network/interceptores/interceptores_sesion.dart';
import '../core/push/receptor_push.dart';
import '../core/push/receptor_push_nulo.dart';
import '../core/session/session_service.dart';
import '../features/analitica/data/analitica_repository.dart';
import '../features/analitica/data/analitica_repository_http.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/auth_repository_http.dart';
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
import 'fakes/analitica_repository_fake.dart';
import 'fakes/comportamiento_fake.dart';
import 'fakes/auth_repository_fake.dart';
import 'fakes/favorito_repository_fake.dart';
import 'fakes/karma_fake.dart';
import 'fakes/lugar_repository_fake.dart';
import 'fakes/moderacion_repository_fake.dart';
import 'fakes/perfil_repository_fake.dart';
import 'fakes/reporte_repository_fake.dart';
import 'fakes/validacion_repository_fake.dart';

/// Composition root (manual dependency injection): builds the object graph once.
///
/// `USAR_FAKES=true` swaps every repository for its in-memory `*RepositoryFake`.
/// A stream that finishes its `<x>_repository_http.dart` changes nothing here.
class Dependencias {
  final Entorno entorno;
  final SessionService sesion;
  final ApiClient apiClient;
  final MapaAdapter mapaAdapter;
  final ReceptorPush receptorPush;
  final AuthRepository authRepository;
  final PerfilRepository perfilRepository;
  final LugarRepository lugarRepository;
  final ReporteRepository reporteRepository;
  final AnaliticaRepository analiticaRepository;
  final ValidacionRepository validacionRepository;
  final FavoritoRepository favoritoRepository;
  final ModeracionRepository moderacionRepository;

  Dependencias._({
    required this.entorno,
    required this.sesion,
    required this.apiClient,
    required this.mapaAdapter,
    required this.receptorPush,
    required this.authRepository,
    required this.perfilRepository,
    required this.lugarRepository,
    required this.reporteRepository,
    required this.analiticaRepository,
    required this.validacionRepository,
    required this.favoritoRepository,
    required this.moderacionRepository,
  });

  /// [mapaAdapter] and [receptorPush] can be overridden (tests, M3).
  /// [esRelease] defaults to `kReleaseMode`; fakes are refused in release.
  factory Dependencias.crear(
    Entorno entorno,
    SessionService sesion, {
    MapaAdapter? mapaAdapter,
    ReceptorPush? receptorPush,
    bool esRelease = kReleaseMode,
  }) {
    if (esRelease && entorno.usarFakes) {
      throw StateError(
        'USAR_FAKES must not be enabled in a release build: fake repositories '
        'and seed credentials are for development only.',
      );
    }
    final api = ApiClient(
      const ClienteHttpFactory().crear(),
      entorno,
      interceptores: interceptoresDeSesion(sesion),
    );
    final repos = entorno.usarFakes
        ? _repositoriosFake(sesion, const ComportamientoFake())
        : _repositoriosHttp(api, sesion);
    return Dependencias._(
      entorno: entorno,
      sesion: sesion,
      apiClient: api,
      mapaAdapter: mapaAdapter ?? FlutterMapAdapter(),
      receptorPush: receptorPush ?? ReceptorPushNulo(),
      authRepository: repos.auth,
      perfilRepository: repos.perfil,
      lugarRepository: repos.lugar,
      reporteRepository: repos.reporte,
      analiticaRepository: repos.analitica,
      validacionRepository: repos.validacion,
      favoritoRepository: repos.favorito,
      moderacionRepository: repos.moderacion,
    );
  }

  // Strategy-style selection of the repository implementation set: both
  // builders return the same shape, so callers never know which one ran.

  static _Repositorios _repositoriosHttp(
    ApiClient api,
    SessionService sesion,
  ) => (
    auth: AuthRepositoryHttp(api, sesion),
    perfil: PerfilRepositoryHttp(api, sesion),
    lugar: LugarRepositoryHttp(api),
    reporte: ReporteRepositoryHttp(api),
    analitica: AnaliticaRepositoryHttp(api),
    validacion: ValidacionRepositoryHttp(api),
    favorito: FavoritoRepositoryHttp(api),
    moderacion: ModeracionRepositoryHttp(api),
  );

  static _Repositorios _repositoriosFake(
    SessionService sesion,
    ComportamientoFake comportamiento,
  ) {
    final karma = KarmaFake();
    return (
    auth: AuthRepositoryFake(sesion, comportamiento: comportamiento),
    perfil: PerfilRepositoryFake(
      sesion,
      comportamiento: comportamiento,
      karma: karma,
    ),
    lugar: LugarRepositoryFake(comportamiento: comportamiento),
    reporte: ReporteRepositoryFake(
      comportamiento: comportamiento,
      karma: karma,
    ),
    analitica: AnaliticaRepositoryFake(comportamiento: comportamiento),
    validacion: ValidacionRepositoryFake(comportamiento: comportamiento),
    favorito: FavoritoRepositoryFake(comportamiento: comportamiento),
    moderacion: ModeracionRepositoryFake(comportamiento: comportamiento),
    );
  }
}

typedef _Repositorios = ({
  AuthRepository auth,
  PerfilRepository perfil,
  LugarRepository lugar,
  ReporteRepository reporte,
  AnaliticaRepository analitica,
  ValidacionRepository validacion,
  FavoritoRepository favorito,
  ModeracionRepository moderacion,
});
