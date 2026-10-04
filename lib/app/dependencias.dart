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

/// Composition root: builds the object graph once.
///
/// A stream that finishes its `<x>_repository_http.dart` changes nothing here;
/// only the constructor call below already points at its class.
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

  factory Dependencias.crear(Entorno entorno, SessionService sesion) {
    final api = ApiClient(
      http.Client(),
      entorno,
      interceptores: interceptoresDeSesion(sesion),
    );
    return Dependencias._(
      entorno: entorno,
      sesion: sesion,
      apiClient: api,
      mapaAdapter: FlutterMapAdapter(),
      receptorPush: ReceptorPushNulo(),
      authRepository: AuthRepositoryHttp(api, sesion),
      perfilRepository: PerfilRepositoryHttp(api, sesion),
      lugarRepository: LugarRepositoryHttp(api),
      reporteRepository: ReporteRepositoryHttp(api),
      analiticaRepository: AnaliticaRepositoryHttp(api),
      validacionRepository: ValidacionRepositoryHttp(api),
      favoritoRepository: FavoritoRepositoryHttp(api),
      moderacionRepository: ModeracionRepositoryHttp(api),
    );
  }
}
