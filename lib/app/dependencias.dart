import 'package:http/http.dart' as http;

import '../core/config/entorno.dart';
import '../core/network/api_client.dart';
import '../core/network/interceptores/interceptores_sesion.dart';
import '../core/session/session_service.dart';
import '../features/auth/data/auth_service.dart';
import '../features/perfil/data/user_service.dart';

/// Composition root: builds the object graph once.
class Dependencias {
  final Entorno entorno;
  final SessionService sesion;
  final ApiClient apiClient;
  // Legacy services; replaced by repositories in FE-05.
  final AuthService authService;
  final UserService userService;

  Dependencias._({
    required this.entorno,
    required this.sesion,
    required this.apiClient,
    required this.authService,
    required this.userService,
  });

  factory Dependencias.crear(Entorno entorno, SessionService sesion) {
    return Dependencias._(
      entorno: entorno,
      sesion: sesion,
      apiClient: ApiClient(
        http.Client(),
        entorno,
        interceptores: interceptoresDeSesion(sesion),
      ),
      authService: AuthService(),
      userService: UserService(),
    );
  }
}
