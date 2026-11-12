import '../core/config/entorno.dart';
import '../core/location/geolocator_ubicacion_service.dart';
import '../core/location/punto_referencia.dart';
import '../core/location/ubicacion_service.dart';
import '../core/map/centro_compartido.dart';
import '../core/map/flutter_map_adapter.dart';
import '../core/map/mapa_adapter.dart';
import '../core/network/api_client.dart';
import '../core/network/cliente_http_factory.dart';
import '../core/network/interceptores/interceptores_sesion.dart';
import '../core/push/receptor_push.dart';
import '../core/push/receptor_push_nulo.dart';
import '../core/session/session_service.dart';
import '../features/alertas/data/alerta_repository.dart';
import '../features/analitica/data/analitica_repository.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/exploracion/data/exploracion_repository.dart';
import '../features/favoritos/data/favorito_repository.dart';
import '../features/lugares/data/lugar_repository.dart';
import '../features/moderacion/data/moderacion_repository.dart';
import '../features/perfil/data/perfil_repository.dart';
import '../features/reportes/data/reporte_repository.dart';
import '../features/validacion/data/validacion_repository.dart';
import 'fabrica_repositorios.dart';

/// Composition root (manual dependency injection): builds the object graph once.
///
/// The repositories come from a [FabricaRepositorios] (HTTP by default).
/// A stream that finishes its `<x>_repository_http.dart` changes nothing here.
class Dependencias {
  final Entorno entorno;
  final SessionService sesion;
  final ApiClient apiClient;
  final MapaAdapter mapaAdapter;
  final UbicacionService ubicacionService;

  /// The map writes its centre here; [puntoReferencia] falls back to it.
  final CentroMapaCompartido centroMapa;

  /// Device location or map centre, shared by every screen that measures
  /// distances or searches nearby (CRO-65).
  final PuntoReferencia puntoReferencia;
  final ReceptorPush receptorPush;
  final AuthRepository authRepository;
  final PerfilRepository perfilRepository;
  final LugarRepository lugarRepository;
  final ReporteRepository reporteRepository;
  final AnaliticaRepository analiticaRepository;
  final ValidacionRepository validacionRepository;
  final FavoritoRepository favoritoRepository;
  final AlertaRepository alertaRepository;
  final ExploracionRepository exploracionRepository;
  final ModeracionRepository moderacionRepository;

  Dependencias._({
    required this.entorno,
    required this.sesion,
    required this.apiClient,
    required this.mapaAdapter,
    required this.ubicacionService,
    required this.centroMapa,
    required this.puntoReferencia,
    required this.receptorPush,
    required this.authRepository,
    required this.perfilRepository,
    required this.lugarRepository,
    required this.reporteRepository,
    required this.analiticaRepository,
    required this.validacionRepository,
    required this.favoritoRepository,
    required this.alertaRepository,
    required this.exploracionRepository,
    required this.moderacionRepository,
  });

  /// [mapaAdapter], [ubicacionService], [receptorPush], [alertaRepository]
  /// and the [repositorios] factory can be overridden (tests). The device
  /// location is real even with fake repositories: they stand in for the
  /// backend, not for the phone. The push receiver defaults to the no-op one,
  /// so tests never reach Firebase; `main.dart` passes `ReceptorPushFcm`.
  factory Dependencias.crear(
    Entorno entorno,
    SessionService sesion, {
    MapaAdapter? mapaAdapter,
    UbicacionService? ubicacionService,
    ReceptorPush? receptorPush,
    AlertaRepository? alertaRepository,
    FabricaRepositorios repositorios = const FabricaRepositoriosHttp(),
  }) {
    final api = ApiClient(
      const ClienteHttpFactory().crear(),
      entorno,
      interceptores: interceptoresDeSesion(sesion),
    );
    final repos = repositorios.crear(api, sesion);
    final ubicacion = ubicacionService ?? GeolocatorUbicacionService();
    final centroMapa = CentroMapaCompartido();
    return Dependencias._(
      entorno: entorno,
      sesion: sesion,
      apiClient: api,
      mapaAdapter: mapaAdapter ?? FlutterMapAdapter(),
      ubicacionService: ubicacion,
      centroMapa: centroMapa,
      puntoReferencia: PuntoReferencia(ubicacion, centroMapa),
      receptorPush: receptorPush ?? ReceptorPushNulo(),
      authRepository: repos.auth,
      perfilRepository: repos.perfil,
      lugarRepository: repos.lugar,
      reporteRepository: repos.reporte,
      analiticaRepository: repos.analitica,
      validacionRepository: repos.validacion,
      favoritoRepository: repos.favorito,
      alertaRepository: alertaRepository ?? repos.alerta,
      exploracionRepository: repos.exploracion,
      moderacionRepository: repos.moderacion,
    );
  }
}
