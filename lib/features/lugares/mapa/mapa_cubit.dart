import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/map/tipos_mapa.dart';
import '../../../core/models/categoria_lugar.dart';
import '../../../core/models/lugar_resumen.dart';
import '../../../core/models/nivel_saturacion.dart';
import '../../../core/utils/mensaje_error.dart';
import '../data/lugar_repository.dart';
import 'mapa_state.dart';

/// Loads the places inside the visible map area.
class MapaCubit extends Cubit<MapaState> {
  static const int limiteLugares = 200;
  static const Duration esperaCamara = Duration(milliseconds: 500);
  static const String mensajeSinConexion =
      'Hubo un error al obtener la información geográfica. Revisa tu conexión e inténtalo de nuevo.';
  static const String mensajeError = 'No pudimos cargar los lugares';
  static const String mensajeZonaVacia = 'No hay lugares en esta zona.';

  /// Empty result under a filter (HU 3.5 c3 / 3.6 c3).
  static const String mensajeSinCategoria =
      'No hay lugares cercanos disponibles para esa categoría.';
  static const String mensajeSinNivel =
      'No hay lugares cercanos con ese nivel de saturación.';
  static const String mensajeSinFiltros =
      'No hay lugares cercanos que cumplan con los filtros seleccionados.';

  final LugarRepository _repositorio;
  final Duration _espera;

  Timer? _temporizador;

  /// Last area requested; a retry repeats it.
  LimitesMapa? _limites;

  /// Live camera area, updated before the debounce fires.
  LimitesMapa? _camara;

  /// Active filters (HU 3.5 / 3.6); every load, pan and retry applies them.
  CategoriaLugar? _categoria;
  NivelSaturacion? _nivel;

  /// Identifies the latest request so a slower, older response is dropped.
  int _solicitud = 0;

  MapaCubit(this._repositorio, {Duration espera = esperaCamara})
    : _espera = espera,
      super(const MapaCargando());

  /// True once an area has been requested.
  bool get yaCargo => _limites != null;

  bool get hayFiltros => _categoria != null || _nivel != null;

  /// Middle of the live camera area, or null before the camera reported one.
  PuntoGeografico? get centro {
    final l = _camara;
    if (l == null) return null;
    return PuntoGeografico((l.norte + l.sur) / 2, (l.este + l.oeste) / 2);
  }

  /// Camera moved: loads [limites] once the camera has been still for [esperaCamara].
  void alMoverCamara(LimitesMapa limites) {
    _camara = limites;
    _temporizador?.cancel();
    _temporizador = Timer(_espera, () => cargar(limites));
  }

  /// Sets the category and level filters (null = no filter) and reloads the
  /// current area; before the first area they only apply to the first load.
  Future<void> aplicarFiltros({
    CategoriaLugar? categoria,
    NivelSaturacion? nivel,
  }) async {
    _categoria = categoria;
    _nivel = nivel;
    final limites = _limites;
    if (limites != null) await cargar(limites, conservarMarcadores: false);
  }

  /// Loads [limites]; [conservarMarcadores] keeps the previous markers while
  /// loading (a pan), instead of clearing them (a filter change).
  Future<void> cargar(
    LimitesMapa limites, {
    bool conservarMarcadores = true,
  }) async {
    _limites = limites;
    _camara ??= limites;
    final solicitud = ++_solicitud;
    final actual = state;
    emit(
      MapaCargando(switch (actual) {
        _ when !conservarMarcadores => const <LugarResumen>[],
        MapaCargado() => actual.lugares,
        MapaCargando() => actual.lugares,
        MapaError() => const <LugarResumen>[],
      }),
    );
    try {
      final res = await _repositorio.buscar(
        bbox: limites,
        categoria: _categoria,
        nivel: _nivel,
        limite: limiteLugares,
      );
      if (_obsoleta(solicitud)) return;
      emit(
        MapaCargado(
          res.items,
          mensajeVacio: res.estaVacia ? _mensajeVacio(res.mensaje) : null,
        ),
      );
    } catch (e) {
      if (_obsoleta(solicitud)) return;
      emit(
        MapaError(
          esErrorSinConexion(e) ? mensajeSinConexion : mensajeError,
          codigo: codigoDeError(e),
          esSinConexion: esErrorSinConexion(e),
        ),
      );
    }
  }

  /// Retries the last requested area; nothing to retry before the first one.
  Future<void> reintentar() async {
    final limites = _limites;
    if (limites != null) await cargar(limites);
  }

  /// Under a filter the empty text explains the filters, not the area.
  String _mensajeVacio(String delServidor) {
    if (_categoria != null && _nivel != null) return mensajeSinFiltros;
    if (_categoria != null) return mensajeSinCategoria;
    if (_nivel != null) return mensajeSinNivel;
    return delServidor.isEmpty ? mensajeZonaVacia : delServidor;
  }

  bool _obsoleta(int solicitud) => isClosed || solicitud != _solicitud;

  @override
  Future<void> close() {
    _temporizador?.cancel();
    return super.close();
  }
}
