import 'package:http/http.dart' as http;

import '../core/config/entorno.dart';
import '../core/network/api_client.dart';
import '../core/map/flutter_map_adapter.dart';
import '../core/map/mapa_adapter.dart';
import '../core/network/interceptores/interceptores_sesion.dart';
import '../core/push/receptor_push.dart';
import '../core/push/receptor_push_nulo.dart';
import '../core/session/session_service.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/auth_repository_http.dart';
import '../features/perfil/data/perfil_repository.dart';
import '../features/perfil/data/perfil_repository_http.dart';

/// Composition root: builds the object graph once.
class Dependencias {
  final Entorno entorno;
  final SessionService sesion;
  final ApiClient apiClient;
  final AuthRepository authRepository;
  final PerfilRepository perfilRepository;
  final MapaAdapter mapaAdapter;
  final ReceptorPush receptorPush;

  Dependencias._({
    required this.entorno,
    required this.sesion,
    required this.apiClient,
    required this.authRepository,
    required this.perfilRepository,
    required this.mapaAdapter,
    required this.receptorPush,
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
      authRepository: AuthRepositoryHttp(api, sesion),
      perfilRepository: PerfilRepositoryHttp(api, sesion),
      mapaAdapter: FlutterMapAdapter(),
      receptorPush: ReceptorPushNulo(),
    );
  }
}
