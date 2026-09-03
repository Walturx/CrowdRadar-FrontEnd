import '../session/usuario_sesion.dart';
import 'token_storage.dart';

/// In-memory storage for tests and fakes mode.
class MemoriaTokenStorage implements TokenStorage {
  String? token;
  UsuarioSesion? usuario;

  @override
  Future<String?> leerToken() async => token;

  @override
  Future<UsuarioSesion?> leerUsuario() async => usuario;

  @override
  Future<void> guardar(String token, UsuarioSesion usuario) async {
    this.token = token;
    this.usuario = usuario;
  }

  @override
  Future<void> borrar() async {
    token = null;
    usuario = null;
  }
}
