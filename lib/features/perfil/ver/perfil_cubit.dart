import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/mensaje_error.dart';
import '../data/perfil_repository.dart';
import 'perfil_state.dart';

class PerfilCubit extends Cubit<PerfilState> {
  final PerfilRepository _repositorio;

  PerfilCubit(this._repositorio) : super(const PerfilCargando());

  /// A load while another is in flight is ignored.
  bool _enVuelo = false;

  Future<void> cargar() async {
    if (isClosed || _enVuelo) return;
    _enVuelo = true;
    emit(const PerfilCargando());
    try {
      final usuario = await _repositorio.obtener();
      if (isClosed) return;
      emit(PerfilCargado(usuario));
    } catch (e) {
      if (isClosed) return;
      emit(
        PerfilError(
          mensajeDeError(e),
          codigo: codigoDeError(e),
          esSinConexion: esErrorSinConexion(e),
        ),
      );
    } finally {
      _enVuelo = false;
    }
  }

  /// Reloads in the background: the data on screen stays until the new data
  /// arrives, and a failure only adds a soft error. Without data it is a
  /// regular [cargar].
  Future<void> refrescar() async {
    if (isClosed) return;
    final actual = state;
    if (actual is! PerfilCargado) return cargar();
    if (_enVuelo) return;
    _enVuelo = true;
    // Clears a previous soft error so a repeated failure is reported again.
    emit(PerfilCargado(actual.usuario));
    try {
      final usuario = await _repositorio.obtener();
      if (isClosed) return;
      emit(PerfilCargado(usuario));
    } catch (e) {
      if (isClosed) return;
      emit(
        PerfilCargado(actual.usuario, errorActualizacion: mensajeDeError(e)),
      );
    } finally {
      _enVuelo = false;
    }
  }
}
