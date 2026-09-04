import '../../core/models/favorito.dart';
import '../../core/network/respuesta_api.dart';
import '../../features/favoritos/data/favorito_repository.dart';
import 'datos_fake.dart';

class FakeFavoritoRepository implements FavoritoRepository {
  final Map<int, Favorito> _favoritos = {};

  @override
  Future<ResultadoLista<Favorito>> listar() async => ResultadoLista(
    mensaje: _favoritos.isEmpty ? 'Aún no tienes lugares favoritos' : '',
    items: _favoritos.values.toList(),
  );

  @override
  Future<void> agregar(int lugarId) async {
    if (_favoritos.containsKey(lugarId)) {
      throw errorFake(409, 'FAVORITO_DUPLICADO', 'El lugar ya es favorito');
    }
    final lugar = lugaresFake.where((l) => l.id == lugarId).firstOrNull;
    _favoritos[lugarId] = Favorito(
      lugarId: lugarId,
      nombre: lugar?.nombre ?? 'Lugar $lugarId',
      categoria: lugar?.categoria,
    );
  }

  @override
  Future<void> eliminar(int lugarId) async {
    if (_favoritos.remove(lugarId) == null) throw _noEncontrado();
  }

  @override
  Future<void> configurarAlertas(int lugarId, {required bool activadas}) async {
    final f = _favoritos[lugarId] ?? (throw _noEncontrado());
    _favoritos[lugarId] = Favorito(
      lugarId: f.lugarId,
      nombre: f.nombre,
      categoria: f.categoria,
      saturacion: f.saturacion,
      alertasActivadas: activadas,
    );
  }

  Object _noEncontrado() =>
      errorFake(404, 'FAVORITO_NO_ENCONTRADO', 'Favorito no encontrado');
}
