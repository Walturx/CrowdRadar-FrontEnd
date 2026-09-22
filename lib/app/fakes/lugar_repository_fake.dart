import '../../core/map/tipos_mapa.dart';
import '../../core/models/categoria_lugar.dart';
import '../../core/models/lugar_detalle.dart';
import '../../core/models/lugar_resumen.dart';
import '../../core/models/nivel_saturacion.dart';
import '../../core/network/respuesta_api.dart';
import '../../features/lugares/data/lugar_repository.dart';
import 'comportamiento_fake.dart';
import 'datos_fake.dart';
import 'datos_lugares_fake.dart';

/// In-memory [LugarRepository] over the 45 seed places, with the same filter
/// semantics and validation as the API.
class LugarRepositoryFake implements LugarRepository {
  static const int _qMinimo = 2;
  static const int _limitePorDefecto = 200;
  static const String _mensajeSinInformacion =
      'Aún no hay reportes suficientes para determinar la saturación de este lugar.';

  final ComportamientoFake _comportamiento;
  final DateTime Function() _reloj;

  LugarRepositoryFake({
    ComportamientoFake comportamiento = const ComportamientoFake(),
    DateTime Function()? reloj,
  }) : _comportamiento = comportamiento,
       _reloj = reloj ?? DateTime.now;

  @override
  Future<ResultadoLista<LugarResumen>> buscar({
    String? q,
    LimitesMapa? bbox,
    CategoriaLugar? categoria,
    NivelSaturacion? nivel,
    int? limite,
  }) async {
    await _comportamiento.aplicar();
    final texto = q?.trim();
    if ((texto == null || texto.isEmpty) && bbox == null) {
      throw errorFake(400, 'VALIDACION_FALLIDA', 'Indica un texto o el área del mapa');
    }
    if (texto != null && texto.length < _qMinimo) {
      throw errorFake(400, 'VALIDACION_FALLIDA', 'La búsqueda requiere al menos 2 caracteres');
    }
    final buscado = texto == null ? null : _normalizar(texto);
    final items = [
      for (final l in datosLugaresFake)
        if ((buscado == null || _normalizar(l.nombre).contains(buscado)) &&
            (bbox == null || _dentro(l, bbox)) &&
            (categoria == null || l.categoria == categoria) &&
            (nivel == null || l.nivel == nivel))
          l.resumen,
    ]..sort((a, b) => a.nombre.compareTo(b.nombre));
    return ResultadoLista(
      mensaje: items.isEmpty ? _mensajeVacio(texto) : '',
      items: items.take(limite ?? _limitePorDefecto).toList(),
    );
  }

  @override
  Future<LugarDetalle> obtener(int id) async {
    await _comportamiento.aplicar();
    for (final l in datosLugaresFake) {
      if (l.id != id) continue;
      final conInformacion = l.nivel != NivelSaturacion.sinInformacion;
      return LugarDetalle(
        id: l.id,
        nombre: l.nombre,
        categoria: l.categoria,
        direccion: l.direccion,
        latitud: l.latitud,
        longitud: l.longitud,
        horarioAtencion: l.horario,
        abiertoAhora: l.horario == null ? null : true,
        saturacion: SaturacionLugar(
          nivel: l.nivel,
          actualizadoEn: conInformacion
              ? _reloj().subtract(Duration(minutes: l.minutosDesdeActualizacion))
              : null,
          reportesRecientes: l.reportesRecientes,
          mensaje: conInformacion ? null : _mensajeSinInformacion,
        ),
      );
    }
    throw errorFake(404, 'LUGAR_NO_ENCONTRADO', 'No se pudo obtener la información del lugar.');
  }

  static String _mensajeVacio(String? q) => q == null || q.isEmpty
      ? 'No hay lugares en esta zona.'
      : 'No encontramos lugares para “$q”. Prueba con otro nombre.';

  static bool _dentro(LugarFake l, LimitesMapa b) =>
      l.latitud <= b.norte &&
      l.latitud >= b.sur &&
      l.longitud <= b.este &&
      l.longitud >= b.oeste;

  /// Lower-cased and without Spanish accents, like the backend's search.
  static String _normalizar(String s) {
    const con = 'áéíóúüñ';
    const sin = 'aeiouun';
    final b = StringBuffer();
    for (final c in s.toLowerCase().split('')) {
      final i = con.indexOf(c);
      b.write(i < 0 ? c : sin[i]);
    }
    return b.toString();
  }
}
