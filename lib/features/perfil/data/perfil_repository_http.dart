import '../../../core/models/user_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/session/session_service.dart';
import '../../../core/session/usuario_sesion.dart';
import 'perfil_repository.dart';

class PerfilRepositoryHttp implements PerfilRepository {
  static const String rutaPerfil = '/api/users/profile';
  static const String rutaPassword = '/api/users/password';
  static const String mensajeSinSesion = 'No hay sesión activa';

  final ApiClient _api;
  final SessionService _sesion;

  PerfilRepositoryHttp(this._api, this._sesion);

  @override
  Future<UserModel> obtener() async {
    _exigirSesion();
    final res = await _api.get<UserModel>(
      rutaPerfil,
      mensajeError: 'Error al obtener el perfil',
      parser: _usuario,
    );
    return res.datos;
  }

  @override
  Future<UserModel> actualizar(Map<String, dynamic> cambios) async {
    _exigirSesion();
    final res = await _api.put<UserModel>(
      rutaPerfil,
      body: cambios,
      mensajeError: 'Error al actualizar el perfil',
      parser: _usuario,
    );
    await _sesion.actualizarUsuario(UsuarioSesion.desdeUserModel(res.datos));
    return res.datos;
  }

  @override
  Future<void> cambiarPassword({
    required String actual,
    required String nueva,
    required String confirmar,
  }) async {
    _exigirSesion();
    await _api.put<void>(
      rutaPassword,
      body: {
        'passwordActual': actual,
        'nuevaPassword': nueva,
        'confirmarPassword': confirmar,
      },
      mensajeError: 'Error al cambiar la contraseña',
      parser: (_) {},
    );
  }

  void _exigirSesion() {
    if (_sesion.token == null) {
      throw const ApiException(status: 401, message: mensajeSinSesion);
    }
  }

  static UserModel _usuario(Object? d) =>
      UserModel.fromJson(d is Map<String, dynamic> ? d : const {});
}
