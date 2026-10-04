import '../../../core/models/usuario.dart';
import '../../../core/network/api_client.dart';
import '../../../core/session/session_service.dart';
import '../../../core/session/usuario_sesion.dart';
import '../../../core/utils/lectura_json.dart';
import 'auth_repository.dart';

/// Repository pattern: HTTP implementation of the [AuthRepository] port.
class AuthRepositoryHttp implements AuthRepository {
  static const String rutaLogin = '/api/auth/login';
  static const String rutaRegistro = '/api/auth/register';
  static const String rutaRecuperar = '/api/auth/recuperar';

  final ApiClient _api;
  final SessionService _sesion;

  AuthRepositoryHttp(this._api, this._sesion);

  @override
  Future<Usuario> iniciarSesion(String email, String password) async {
    final res = await _api.post<({String token, Usuario user})>(
      rutaLogin,
      body: {'email': email, 'password': password},
      mensajeError: 'Error al iniciar sesión',
      parser: (d) {
        final data = aMapa(d);
        final token = data['token'];
        final user = data['user'];
        if (token is! String ||
            token.isEmpty ||
            user is! Map<String, dynamic>) {
          throw const FormatException('Login response lacks token or user');
        }
        return (token: token, user: Usuario.fromJson(user));
      },
    );
    await _sesion.iniciar(
      res.datos.token,
      UsuarioSesion.desdeUsuario(res.datos.user),
    );
    return res.datos.user;
  }

  @override
  Future<Usuario> registrar({
    required String nombre,
    required String apellido,
    required String email,
    required String password,
    required String telefono,
    required String distrito,
  }) async {
    final res = await _api.post<Usuario>(
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
      parser: (d) {
        final data = aMapa(d);
        if (data.isEmpty) {
          throw const FormatException('Register response lacks the user');
        }
        return Usuario.fromJson(data);
      },
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
}
