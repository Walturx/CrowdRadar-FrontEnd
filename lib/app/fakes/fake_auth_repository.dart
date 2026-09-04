import '../../core/models/user_model.dart';
import '../../core/session/session_service.dart';
import '../../core/session/usuario_sesion.dart';
import '../../features/auth/data/auth_repository.dart';
import 'datos_fake.dart';

class FakeAuthRepository implements AuthRepository {
  final SessionService _sesion;
  final Set<String> _emails = {emailFake};

  FakeAuthRepository(this._sesion);

  @override
  Future<UserModel> iniciarSesion(String email, String password) async {
    if (email != emailFake || password != passwordFake) {
      throw errorFake(401, 'CREDENCIALES_INVALIDAS', 'Credenciales inválidas');
    }
    await _sesion.iniciar(
      'token-fake',
      UsuarioSesion.desdeUserModel(usuarioFake),
    );
    return usuarioFake;
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
    if (!_emails.add(email)) {
      throw errorFake(409, 'EMAIL_DUPLICADO', 'El email ya está registrado');
    }
    return UserModel(
      id: _emails.length,
      nombre: nombre,
      apellido: apellido,
      email: email,
      telefono: telefono,
      distrito: distrito,
      rol: 'USUARIO',
      status: 'ACTIVO',
    );
  }

  @override
  Future<void> solicitarRecuperacion(String email) async {}
}
