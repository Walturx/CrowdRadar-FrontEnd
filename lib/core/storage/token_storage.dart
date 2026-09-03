import '../session/usuario_sesion.dart';

abstract class TokenStorage {
  Future<String?> leerToken();

  Future<UsuarioSesion?> leerUsuario();

  Future<void> guardar(String token, UsuarioSesion usuario);

  Future<void> borrar();
}
