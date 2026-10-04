import '../../core/models/usuario.dart';
import '../../core/session/session_service.dart';
import '../../core/session/usuario_sesion.dart';
import '../../features/perfil/data/perfil_repository.dart';
import 'comportamiento_fake.dart';
import 'datos_fake.dart';
import 'karma_fake.dart';

class PerfilRepositoryFake implements PerfilRepository {
  final SessionService _sesion;
  Usuario _perfil = usuarioFake;
  String _password = passwordFake;

  final ComportamientoFake _comportamiento;
  final KarmaFake _karma;

  /// [karma] is shared with the report fake so both show the same total.
  PerfilRepositoryFake(
    this._sesion, {
    ComportamientoFake comportamiento = const ComportamientoFake(),
    KarmaFake? karma,
  }) : _comportamiento = comportamiento,
       _karma = karma ?? KarmaFake();

  @override
  Future<Usuario> obtener() async {
    await _comportamiento.aplicar();
    _exigirSesion();
    return _perfil.copyWith(puntosKarma: _karma.total);
  }

  @override
  Future<Usuario> actualizar(Map<String, dynamic> cambios) async {
    await _comportamiento.aplicar();
    _exigirSesion();
    _perfil = _perfil.copyWith(
      nombre: cambios['nombre'] as String?,
      apellido: cambios['apellido'] as String?,
      telefono: cambios['telefono'] as String?,
      distrito: cambios['distrito'] as String?,
    );
    await _sesion.actualizarUsuario(UsuarioSesion.desdeUsuario(_perfil));
    return _perfil.copyWith(puntosKarma: _karma.total);
  }

  @override
  Future<void> cambiarPassword({
    required String actual,
    required String nueva,
    required String confirmar,
  }) async {
    await _comportamiento.aplicar();
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
