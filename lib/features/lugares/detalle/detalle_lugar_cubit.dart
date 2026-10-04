import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/mensaje_error.dart';
import '../../favoritos/data/favorito_repository.dart';
import '../data/lugar_repository.dart';
import 'detalle_lugar_state.dart';

class DetalleLugarCubit extends Cubit<DetalleLugarState> {
  static const String mensajeError =
      'No pudimos obtener la información de este lugar. Inténtalo más tarde.';
  static const String mensajeNoEncontrado = 'Este lugar ya no está disponible.';

  static const String _codigoFavoritoDuplicado = 'FAVORITO_DUPLICADO';
  static const String _codigoFavoritoNoEncontrado = 'FAVORITO_NO_ENCONTRADO';

  final LugarRepository _lugares;
  final FavoritoRepository _favoritos;
  final int _lugarId;

  DetalleLugarCubit(this._lugares, this._favoritos, this._lugarId)
    : super(const DetalleCargando());

  /// A load while another is in flight is ignored.
  bool _enVuelo = false;

  /// Counts favorite toggles; a refresh that overlapped one must not bring
  /// back the favorite flag the server had before it.
  int _alternancias = 0;

  Future<void> cargar() async {
    if (isClosed || _enVuelo) return;
    _enVuelo = true;
    emit(const DetalleCargando());
    try {
      final detalle = await _lugares.obtener(_lugarId);
      if (isClosed) return;
      emit(DetalleCargado(detalle, esFavorito: detalle.esFavorito));
    } catch (e) {
      if (isClosed) return;
      final codigo = codigoDeError(e);
      emit(
        DetalleError(
          codigo == DetalleError.codigoNoEncontrado
              ? mensajeNoEncontrado
              : mensajeError,
          codigo: codigo,
          esSinConexion: esErrorSinConexion(e),
        ),
      );
    } finally {
      _enVuelo = false;
    }
  }

  /// Reloads in the background: the detail on screen stays until the new one
  /// arrives, and a failure only adds a soft error. Without a detail it is a
  /// regular [cargar].
  Future<void> refrescar() async {
    final actual = state;
    if (actual is! DetalleCargado) return cargar();
    if (isClosed || _enVuelo) return;
    _enVuelo = true;
    final alternanciasAlInicio = _alternancias;
    // Clears a previous soft error so a repeated failure is reported again.
    emit(DetalleCargado(actual.detalle, esFavorito: actual.esFavorito));
    try {
      final detalle = await _lugares.obtener(_lugarId);
      if (isClosed) return;
      final ahora = state;
      if (ahora is DetalleCargado && _alternancias != alternanciasAlInicio) {
        // A toggle overlapped: its flag (optimistic or final) wins.
        emit(
          DetalleCargado(
            detalle,
            esFavorito: ahora.esFavorito,
            procesandoFavorito: ahora.procesandoFavorito,
            errorFavorito: ahora.errorFavorito,
          ),
        );
      } else {
        emit(DetalleCargado(detalle, esFavorito: detalle.esFavorito));
      }
    } catch (e) {
      if (isClosed) return;
      final ahora = state;
      emit(
        DetalleCargado(
          ahora is DetalleCargado ? ahora.detalle : actual.detalle,
          esFavorito: ahora is DetalleCargado
              ? ahora.esFavorito
              : actual.esFavorito,
          procesandoFavorito:
              ahora is DetalleCargado && ahora.procesandoFavorito,
          errorActualizacion: mensajeDeError(e),
        ),
      );
    } finally {
      _enVuelo = false;
    }
  }

  Future<void> alternarFavorito() async {
    final actual = state;
    if (actual is! DetalleCargado || actual.procesandoFavorito) return;
    _alternancias++;
    emit(
      DetalleCargado(
        actual.detalle,
        esFavorito: actual.esFavorito,
        procesandoFavorito: true,
      ),
    );
    var esFavorito = actual.esFavorito;
    String? error;
    try {
      if (esFavorito) {
        await _favoritos.eliminar(_lugarId);
      } else {
        await _favoritos.agregar(_lugarId);
      }
      esFavorito = !esFavorito;
    } on ApiException catch (e) {
      // The server already agrees with the wanted end state.
      if (e.code == _codigoFavoritoDuplicado) {
        esFavorito = true;
      } else if (e.code == _codigoFavoritoNoEncontrado) {
        esFavorito = false;
      } else {
        error = mensajeDeError(e);
      }
    } catch (e) {
      error = mensajeDeError(e);
    }
    if (isClosed) return;
    // A refresh may have swapped the detail while the toggle was in flight.
    final ahora = state;
    emit(
      DetalleCargado(
        ahora is DetalleCargado ? ahora.detalle : actual.detalle,
        esFavorito: esFavorito,
        errorFavorito: error,
      ),
    );
  }
}
