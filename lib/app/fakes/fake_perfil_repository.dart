import '../../core/models/user_model.dart';
import '../../core/session/session_service.dart';
import '../../core/session/usuario_sesion.dart';
import '../../features/perfil/data/perfil_repository.dart';
import 'datos_fake.dart';

class FakePerfilRepository implements PerfilRepository {
  final SessionService _sesion;
  UserModel _perfil = usuarioFake;
  String _password = passwordFake;

  FakePerfilRepository(this._sesion);

  @override
  Future<UserModel> obtener() async {
    _exigirSesion();
    return _perfil;
  }

  @override
  Future<UserModel> actualizar(Map<String, dynamic> cambios) async {
    _exigirSesion();
    _perfil = _perfil.copyWith(
      nombre: cambios['nombre'] as String?,
      apellido: cambios['apellido'] as String?,
      telefono: cambios['telefono'] as String?,
      distrito: cambios['distrito'] as String?,
    );
    await _sesion.actualizarUsuario(UsuarioSesion.desdeUserModel(_perfil));
    return _perfil;
  }

  @override
  Future<void> cambiarPassword({
    required String actual,
    required String nueva,
    required String confirmar,
  }) async {
    _exigirSesion();
    if (actual != _password) {
      throw errorFake(
        422,
        'PASSWORD_ACTUAL_INCORRECTA',
        'La contraseña actual es incorrecta',
      );
    }
    if (nueva == actual) {
      throw errorFake(
        422,
        'PASSWORD_REPETIDA',
        'La nueva contraseña debe ser distinta de la actual',
      );
    }
    _password = nueva;
  }

  void _exigirSesion() {
    if (_sesion.token == null) {
      throw errorFake(401, 'NO_AUTENTICADO', 'No hay sesión activa');
    }
  }
}
