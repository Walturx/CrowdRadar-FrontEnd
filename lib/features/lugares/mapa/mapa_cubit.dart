import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/map/tipos_mapa.dart';
import '../../../core/models/lugar_resumen.dart';
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

  final LugarRepository _repositorio;
  final Duration _espera;

  Timer? _temporizador;

  /// Last area requested; a retry repeats it.
  LimitesMapa? _limites;

  /// Live camera area, updated before the debounce fires.
  LimitesMapa? _camara;

  /// Identifies the latest request so a slower, older response is dropped.
  int _solicitud = 0;

  MapaCubit(this._repositorio, {Duration espera = esperaCamara})
    : _espera = espera,
      super(const MapaCargando());

  /// True once an area has been requested.
  bool get yaCargo => _limites != null;

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

  Future<void> cargar(LimitesMapa limites) async {
    _limites = limites;
    _camara ??= limites;
    final solicitud = ++_solicitud;
    final actual = state;
    emit(
      MapaCargando(switch (actual) {
        MapaCargado() => actual.lugares,
        MapaCargando() => actual.lugares,
        MapaError() => const <LugarResumen>[],
      }),
    );
    try {
      final res = await _repositorio.buscar(
        bbox: limites,
        limite: limiteLugares,
      );
      if (_obsoleta(solicitud)) return;
      emit(
        MapaCargado(
          res.items,
          mensajeVacio: res.estaVacia
              ? (res.mensaje.isEmpty ? mensajeZonaVacia : res.mensaje)
              : null,
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

  bool _obsoleta(int solicitud) => isClosed || solicitud != _solicitud;

  @override
  Future<void> close() {
    _temporizador?.cancel();
    return super.close();
  }
}
