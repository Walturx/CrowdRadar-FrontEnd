import '../../../core/models/user_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/session/session_service.dart';
import '../../../core/session/usuario_sesion.dart';
import 'auth_repository.dart';

class AuthRepositoryHttp implements AuthRepository {
  static const String rutaLogin = '/api/auth/login';
  static const String rutaRegistro = '/api/auth/register';
  static const String rutaRecuperar = '/api/auth/recuperar';

  final ApiClient _api;
  final SessionService _sesion;

  AuthRepositoryHttp(this._api, this._sesion);

  @override
  Future<UserModel> iniciarSesion(String email, String password) async {
    final res = await _api.post<({String token, UserModel user})>(
      rutaLogin,
      body: {'email': email, 'password': password},
      mensajeError: 'Error al iniciar sesión',
      parser: (d) {
        final data = _mapa(d);
        return (
          token: data['token'] as String? ?? '',
          user: UserModel.fromJson(_mapa(data['user'])),
        );
      },
    );
    await _sesion.iniciar(
      res.datos.token,
      UsuarioSesion.desdeUserModel(res.datos.user),
    );
    return res.datos.user;
  }

  @override
  Future<UserModel> registrar({
    required String nombre,
    required String apellido,
    required String email,
    required String password,
    required String telefono,
    required String distrito,
  }) async {
    final res = await _api.post<UserModel>(
      rutaRegistro,
      body: {
        'nombre': nombre,
        'apellido': apellido,
        'email': email,
        'password': password,
        'telefono': telefono,
        'distrito': distrito,
      },
      mensajeError: 'Error al registrar usuario',
      parser: (d) => UserModel.fromJson(_mapa(d)),
    );
    return res.datos;
  }

  @override
  Future<void> solicitarRecuperacion(String email) async {
    await _api.post<void>(
      rutaRecuperar,
      body: {'email': email},
      parser: (_) {},
    );
  }

  static Map<String, dynamic> _mapa(Object? d) =>
      d is Map<String, dynamic> ? d : const {};
}
