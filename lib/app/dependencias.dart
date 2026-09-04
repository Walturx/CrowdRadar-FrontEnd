import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/config/entorno.dart';
import '../core/map/flutter_map_adapter.dart';
import '../core/map/mapa_adapter.dart';
import '../core/network/api_client.dart';
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
import 'fakes/fake_analitica_repository.dart';
import 'fakes/fake_auth_repository.dart';
import 'fakes/fake_favorito_repository.dart';
import 'fakes/fake_lugar_repository.dart';
import 'fakes/fake_moderacion_repository.dart';
import 'fakes/fake_perfil_repository.dart';
import 'fakes/fake_reporte_repository.dart';
import 'fakes/fake_validacion_repository.dart';

/// Composition root (manual dependency injection): builds the object graph once.
///
/// `USAR_FAKES=true` swaps every repository for its in-memory `Fake*`.
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
      http.Client(),
      entorno,
      interceptores: interceptoresDeSesion(sesion),
    );
    final fakes = entorno.usarFakes;
    return Dependencias._(
      entorno: entorno,
      sesion: sesion,
      apiClient: api,
      mapaAdapter: mapaAdapter ?? FlutterMapAdapter(),
      receptorPush: receptorPush ?? ReceptorPushNulo(),
      authRepository:
          fakes ? FakeAuthRepository(sesion) : AuthRepositoryHttp(api, sesion),
      perfilRepository: fakes
          ? FakePerfilRepository(sesion)
          : PerfilRepositoryHttp(api, sesion),
      lugarRepository: fakes ? FakeLugarRepository() : LugarRepositoryHttp(api),
      reporteRepository:
          fakes ? FakeReporteRepository() : ReporteRepositoryHttp(api),
      analiticaRepository:
          fakes ? FakeAnaliticaRepository() : AnaliticaRepositoryHttp(api),
      validacionRepository:
          fakes ? FakeValidacionRepository() : ValidacionRepositoryHttp(api),
      favoritoRepository:
          fakes ? FakeFavoritoRepository() : FavoritoRepositoryHttp(api),
      moderacionRepository:
          fakes ? FakeModeracionRepository() : ModeracionRepositoryHttp(api),
    );
  }
}
