import '../../core/map/tipos_mapa.dart';
import '../../core/models/categoria_lugar.dart';
import '../../core/models/lugar_resumen.dart';
import '../../core/network/respuesta_api.dart';
import '../../core/session/session_service.dart';
import '../../core/utils/distancia.dart';
import '../../features/exploracion/data/categoria_resumen.dart';
import '../../features/exploracion/data/exploracion_repository.dart';
import '../../features/exploracion/data/filtro_exploracion.dart';
import 'comportamiento_fake.dart';
import 'datos_fake.dart';
import 'datos_lugares_fake.dart';

/// In-memory exploration over the 45 seed places with the API's semantics:
/// filters AND-combine, `lat`/`lng` go together (radius 2 km by default),
/// results are ordered by distance (or by name without a position).
class ExploracionRepositoryFake implements ExploracionRepository {
  static const double radioPorDefectoKm = 2;
  static const double _radioMinimoKm = 0.1;
  static const double _radioMaximoKm = 20;

  static const String mensajeCategoria =
      'No hay lugares cercanos disponibles para esa categoría.';
  static const String mensajeSaturacion =
      'No hay lugares cercanos con ese nivel de saturación.';
  static const String mensajeFiltros =
      'No hay lugares cercanos que cumplan con los filtros seleccionados.';

  static const Map<CategoriaLugar, String> _etiquetas = {
    CategoriaLugar.parque: 'Parques',
    CategoriaLugar.centroComercial: 'Centros comerciales',
    CategoriaLugar.mercado: 'Mercados',
    CategoriaLugar.transporte: 'Transporte',
    CategoriaLugar.plaza: 'Plazas',
    CategoriaLugar.playa: 'Playas',
  };

  final ComportamientoFake _comportamiento;
  final SessionService? _sesion;

  ExploracionRepositoryFake({
    ComportamientoFake comportamiento = const ComportamientoFake(),
    SessionService? sesion,
  }) : _comportamiento = comportamiento,
       _sesion = sesion;

  @override
  Future<ResultadoLista<LugarResumen>> explorar(
    FiltroExploracion filtro,
  ) async {
    await _entrar();
    final lat = filtro.lat;
    final lng = filtro.lng;
    if ((lat == null) != (lng == null)) {
      throw _invalido('lat y lng deben enviarse juntos');
    }
    final radio = filtro.radioKm ?? radioPorDefectoKm;
    if (radio < _radioMinimoKm || radio > _radioMaximoKm) {
      throw _invalido('radioKm debe estar entre 0.1 y 20');
    }
    final centro = lat == null ? null : PuntoGeografico(lat, lng!);
    final items = <LugarResumen>[
      for (final l in lugaresFake)
        if ((filtro.categoria == null || l.categoria == filtro.categoria) &&
            (filtro.saturacion == null || l.saturacion == filtro.saturacion))
          ?_conDistancia(l, centro, radio),
    ];
    items.sort(
      (a, b) => centro == null
          ? a.nombre.compareTo(b.nombre)
          : a.distanciaMetros!.compareTo(b.distanciaMetros!),
    );
    return ResultadoLista(
      mensaje: items.isEmpty ? _mensajeVacio(filtro) : '',
      items: items,
    );
  }

  @override
  Future<List<CategoriaResumen>> listarCategorias() async {
    await _entrar();
    return [
      for (final c in CategoriaLugar.values)
        CategoriaResumen(
          categoria: c,
          etiqueta: _etiquetas[c]!,
          total: lugaresFake.where((l) => l.categoria == c).length,
        ),
    ];
  }

  static LugarResumen? _conDistancia(
    LugarResumen l,
    PuntoGeografico? centro,
    double radioKm,
  ) {
    if (centro == null) return l;
    final metros = distanciaMetros(
      centro,
      PuntoGeografico(l.latitud, l.longitud),
    );
    if (metros > radioKm * 1000) return null;
    return LugarResumen(
      id: l.id,
      nombre: l.nombre,
      categoria: l.categoria,
      latitud: l.latitud,
      longitud: l.longitud,
      saturacion: l.saturacion,
      distanciaMetros: metros,
    );
  }

  static String _mensajeVacio(FiltroExploracion f) {
    if (f.categoria != null && f.saturacion == null) return mensajeCategoria;
    if (f.saturacion != null && f.categoria == null) return mensajeSaturacion;
    return mensajeFiltros;
  }

  Object _invalido(String mensaje) =>
      errorFake(400, 'VALIDACION_FALLIDA', mensaje);

  Future<void> _entrar() async {
    await _comportamiento.aplicar();
    if (_sesion != null && _sesion.token == null) {
      throw errorFake(401, 'NO_AUTENTICADO', 'No hay sesión activa');
    }
  }
}
