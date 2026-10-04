import '../../core/map/tipos_mapa.dart';
import '../../core/models/lugar_detalle.dart';
import '../../core/models/lugar_resumen.dart';
import '../../core/network/respuesta_api.dart';
import '../../features/lugares/data/lugar_repository.dart';
import 'comportamiento_fake.dart';
import 'datos_fake.dart';

class FakeLugarRepository implements LugarRepository {
  final ComportamientoFake _comportamiento;

  FakeLugarRepository({
    ComportamientoFake comportamiento = const ComportamientoFake(),
  }) : _comportamiento = comportamiento;

  @override
  Future<ResultadoLista<LugarResumen>> buscar({
    String? consulta,
    LimitesMapa? limites,
  }) async {
    await _comportamiento.aplicar();
    final q = consulta?.trim().toLowerCase();
    final items = [
      for (final l in lugaresFake)
        if ((q == null || l.nombre.toLowerCase().contains(q)) &&
            (limites == null || _dentro(l, limites)))
          l,
    ];
    return ResultadoLista(
      mensaje: items.isEmpty ? 'No se encontraron lugares' : '',
      items: items,
    );
  }

  @override
  Future<LugarDetalle> obtenerDetalle(int lugarId) async {
    await _comportamiento.aplicar();
    for (final l in lugaresFake) {
      if (l.id == lugarId) {
        return LugarDetalle(
          id: l.id,
          nombre: l.nombre,
          categoria: l.categoria,
          latitud: l.latitud,
          longitud: l.longitud,
          abiertoAhora: true,
          saturacion: SaturacionLugar(
            nivel: l.saturacion,
            reportesRecientes: 3,
          ),
        );
      }
    }
    throw errorFake(404, 'LUGAR_NO_ENCONTRADO', 'Lugar no encontrado');
  }

  static bool _dentro(LugarResumen l, LimitesMapa b) =>
      l.latitud <= b.norte &&
      l.latitud >= b.sur &&
      l.longitud <= b.este &&
      l.longitud >= b.oeste;
}
