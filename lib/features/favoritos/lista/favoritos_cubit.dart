import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/favorito.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/mensaje_error.dart';
import '../data/favorito_repository.dart';
import 'favoritos_state.dart';

/// HU 8.2 / 8.3 / 8.4: lists the favorites, removes them (with undo) and
/// manages their alert preference one by one or all at once.
class FavoritosCubit extends Cubit<FavoritosState> {
  /// Server text of an empty list, reproduced when the last favorite goes.
  static const String mensajeVacio = 'No tienes lugares favoritos registrados.';

  static const String _codigoNoEncontrado = 'FAVORITO_NO_ENCONTRADO';
  static const String _codigoDuplicado = 'FAVORITO_DUPLICADO';

  final FavoritoRepository _repositorio;

  FavoritosCubit(this._repositorio) : super(const FavoritosCargando());

  /// A load while another is in flight is ignored.
  bool _enVuelo = false;

  FavoritosCargado? get _cargado {
    final actual = state;
    return actual is FavoritosCargado ? actual : null;
  }

  Future<void> cargar() async {
    if (isClosed || _enVuelo) return;
    _enVuelo = true;
    emit(const FavoritosCargando());
    try {
      final res = await _repositorio.listar();
      if (isClosed) return;
      emit(FavoritosCargado(res.items, mensajeVacio: res.mensaje));
    } catch (e) {
      if (isClosed) return;
      emit(
        FavoritosError(
          mensajeDeError(e),
          codigo: codigoDeError(e),
          esSinConexion: esErrorSinConexion(e),
        ),
      );
    } finally {
      _enVuelo = false;
    }
  }

  /// Reloads in the background: the list on screen stays until the new one
  /// arrives, and a failure only adds a soft error. Without a list it is a
  /// regular [cargar].
  Future<void> refrescar() async {
    final actual = _cargado;
    if (actual == null) return cargar();
    if (isClosed || _enVuelo) return;
    _enVuelo = true;
    // Clears a previous soft error so a repeated failure is reported again.
    emit(actual.copiar());
    try {
      await _recargar();
    } finally {
      _enVuelo = false;
    }
  }

  /// Removes a favorite; a 404 means it was already gone.
  Future<void> eliminar(int lugarId) async {
    final actual = _cargado;
    if (actual == null || actual.procesando.contains(lugarId)) return;
    final favorito = actual.favoritos.where((f) => f.lugarId == lugarId);
    if (favorito.isEmpty) return;
    _marcarEnProceso(lugarId);
    Favorito? eliminado;
    String? error;
    try {
      await _repositorio.eliminar(lugarId);
      eliminado = favorito.first;
    } on ApiException catch (e) {
      if (e.code == _codigoNoEncontrado) {
        eliminado = favorito.first;
      } else {
        error = mensajeDeError(e);
      }
    } catch (e) {
      error = mensajeDeError(e);
    }
    final ahora = _cargado;
    if (isClosed || ahora == null) return;
    final restantes = [
      for (final f in ahora.favoritos)
        if (eliminado == null || f.lugarId != lugarId) f,
    ];
    emit(
      ahora.copiar(
        favoritos: restantes,
        mensajeVacio: restantes.isEmpty ? mensajeVacio : ahora.mensajeVacio,
        eliminado: eliminado,
        error: error,
        procesando: {...ahora.procesando}..remove(lugarId),
      ),
    );
  }

  /// Puts back the favorite removed last (and its alert preference).
  Future<void> deshacerEliminar() async {
    final eliminado = _cargado?.eliminado;
    if (eliminado == null) return;
    String? error;
    try {
      try {
        await _repositorio.agregar(eliminado.lugarId);
      } on ApiException catch (e) {
        if (e.code != _codigoDuplicado) rethrow;
      }
      if (!eliminado.alertasActivadas) {
        await _repositorio.configurarAlertas(eliminado.lugarId, activadas: false);
      }
    } catch (e) {
      error = mensajeDeError(e);
    }
    await _recargar(error: error);
  }

  /// Flips the alert preference of one favorite.
  Future<void> alternarAlertas(int lugarId) async {
    final actual = _cargado;
    if (actual == null || actual.procesando.contains(lugarId)) return;
    final f = actual.favoritos.where((f) => f.lugarId == lugarId);
    if (f.isEmpty) return;
    final activadas = !f.first.alertasActivadas;
    _marcarEnProceso(lugarId);
    String? error;
    try {
      await _repositorio.configurarAlertas(lugarId, activadas: activadas);
    } catch (e) {
      error = mensajeDeError(e);
    }
    final ahora = _cargado;
    if (isClosed || ahora == null) return;
    emit(
      ahora.copiar(
        favoritos: error == null
            ? _conAlertas(ahora.favoritos, lugarId, activadas)
            : null,
        error: error,
        procesando: {...ahora.procesando}..remove(lugarId),
      ),
    );
  }

  /// Master switch: when every favorite has alerts on it turns them all off,
  /// otherwise it turns them all on (one request per favorite that differs).
  Future<void> alternarTodasLasAlertas() async {
    final actual = _cargado;
    if (actual == null || actual.favoritos.isEmpty) return;
    final activadas = !actual.todasConAlertas;
    final ids = {for (final f in actual.favoritos) f.lugarId};
    emit(actual.copiar(procesando: ids));
    String? error;
    try {
      for (final f in actual.favoritos) {
        if (f.alertasActivadas == activadas) continue;
        await _repositorio.configurarAlertas(f.lugarId, activadas: activadas);
        final ahora = _cargado;
        if (isClosed || ahora == null) return;
        emit(
          ahora.copiar(
            favoritos: _conAlertas(ahora.favoritos, f.lugarId, activadas),
            procesando: ids,
          ),
        );
      }
    } catch (e) {
      error = mensajeDeError(e);
    }
    if (isClosed) return;
    if (error == null) {
      final ahora = _cargado;
      if (ahora != null) emit(ahora.copiar(procesando: const {}));
    } else {
      // Some favorites may have changed: show what the server holds.
      await _recargar(error: error);
    }
  }

  void _marcarEnProceso(int lugarId) {
    final actual = _cargado;
    if (actual == null || isClosed) return;
    emit(actual.copiar(procesando: {...actual.procesando, lugarId}));
  }

  /// Reads the list again keeping the data on screen when it fails.
  Future<void> _recargar({String? error}) async {
    try {
      final res = await _repositorio.listar();
      if (isClosed) return;
      emit(FavoritosCargado(res.items, mensajeVacio: res.mensaje, error: error));
    } catch (e) {
      if (isClosed) return;
      final actual = _cargado;
      if (actual == null) {
        emit(
          FavoritosError(
            mensajeDeError(e),
            codigo: codigoDeError(e),
            esSinConexion: esErrorSinConexion(e),
          ),
        );
      } else {
        emit(
          actual.copiar(
            error: error ?? mensajeDeError(e),
            procesando: const {},
          ),
        );
      }
    }
  }

  static List<Favorito> _conAlertas(
    List<Favorito> favoritos,
    int lugarId,
    bool activadas,
  ) => [
    for (final f in favoritos)
      if (f.lugarId == lugarId)
        Favorito(
          lugarId: f.lugarId,
          nombre: f.nombre,
          categoria: f.categoria,
          saturacion: f.saturacion,
          alertasActivadas: activadas,
        )
      else
        f,
  ];
}
