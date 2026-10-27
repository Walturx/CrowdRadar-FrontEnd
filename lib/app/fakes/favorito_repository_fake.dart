import '../../core/models/favorito.dart';
import '../../core/network/respuesta_api.dart';
import '../../core/session/session_service.dart';
import '../../features/favoritos/data/favorito_repository.dart';
import 'comportamiento_fake.dart';
import 'datos_fake.dart';
import 'datos_lugares_fake.dart';

/// In-memory favorites with the backend rules: 409 on a duplicate, 404 for an
/// unknown place or a missing favorite, newest first, alerts on by default.
class FavoritoRepositoryFake implements FavoritoRepository {
  static const String mensajeVacio = 'No tienes lugares favoritos registrados.';
  static const String mensajeDuplicado =
      'Este lugar ya pertenece a tus favoritos.';

  final ComportamientoFake _comportamiento;

  /// When given, every call needs a signed-in session like the real backend.
  final SessionService? _sesion;

  FavoritoRepositoryFake({
    ComportamientoFake comportamiento = const ComportamientoFake(),
    SessionService? sesion,
  }) : _comportamiento = comportamiento,
       _sesion = sesion;

  /// Newest first.
  final List<Favorito> _favoritos = [];

  @override
  Future<ResultadoLista<Favorito>> listar() async {
    await _entrar();
    return ResultadoLista(
      mensaje: _favoritos.isEmpty ? mensajeVacio : '',
      items: List.of(_favoritos),
    );
  }

  @override
  Future<void> agregar(int lugarId) async {
    await _entrar();
    final lugar = lugaresFake.where((l) => l.id == lugarId).firstOrNull;
    if (lugar == null) {
      throw errorFake(404, 'LUGAR_NO_ENCONTRADO', 'El lugar no existe');
    }
    if (_indice(lugarId) >= 0) {
      throw errorFake(409, 'FAVORITO_DUPLICADO', mensajeDuplicado);
    }
    _favoritos.insert(
      0,
      Favorito(
        lugarId: lugarId,
        nombre: lugar.nombre,
        categoria: lugar.categoria,
        saturacion: lugar.saturacion,
        alertasActivadas: true,
      ),
    );
  }

  @override
  Future<void> eliminar(int lugarId) async {
    await _entrar();
    _favoritos.removeAt(_existente(lugarId));
  }

  @override
  Future<void> configurarAlertas(int lugarId, {required bool activadas}) async {
    await _entrar();
    final i = _existente(lugarId);
    final f = _favoritos[i];
    _favoritos[i] = Favorito(
      lugarId: f.lugarId,
      nombre: f.nombre,
      categoria: f.categoria,
      saturacion: f.saturacion,
      alertasActivadas: activadas,
    );
  }

  Future<void> _entrar() async {
    await _comportamiento.aplicar();
    if (_sesion != null && _sesion.token == null) {
      throw errorFake(401, 'NO_AUTENTICADO', 'No hay sesión activa');
    }
  }

  int _indice(int lugarId) =>
      _favoritos.indexWhere((f) => f.lugarId == lugarId);

  int _existente(int lugarId) {
    final i = _indice(lugarId);
    if (i < 0) {
      throw errorFake(404, 'FAVORITO_NO_ENCONTRADO', 'Favorito no encontrado');
    }
    return i;
  }
}
