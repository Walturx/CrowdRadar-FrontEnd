import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/mensaje_error.dart';
import '../data/validacion_repository.dart';
import 'estado_validacion_state.dart';

/// HU 5.3: validation status of my reports (first page of the newest ones).
class EstadoValidacionCubit extends Cubit<EstadoValidacionState> {
  /// Largest page the backend allows.
  static const int tamano = 50;

  final ValidacionRepository _repositorio;

  EstadoValidacionCubit(this._repositorio)
    : super(const EstadoValidacionCargando());

  bool _cargando = false;

  Future<void> cargar() async {
    if (isClosed || _cargando) return;
    _cargando = true;
    final actual = state;
    if (actual is! EstadoValidacionCargado) {
      emit(const EstadoValidacionCargando());
    }
    try {
      final pagina = await _repositorio.estadoMisReportes(size: tamano);
      if (isClosed) return;
      emit(
        EstadoValidacionCargado(
          pagina.items,
          filtro: actual is EstadoValidacionCargado
              ? actual.filtro
              : FiltroEstadoValidacion.todos,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        actual is EstadoValidacionCargado
            ? EstadoValidacionCargado(
                actual.reportes,
                filtro: actual.filtro,
                errorActualizacion: mensajeDeError(e),
              )
            : EstadoValidacionError(
                mensajeDeError(e),
                esSinConexion: esErrorSinConexion(e),
              ),
      );
    } finally {
      _cargando = false;
    }
  }

  void filtrar(FiltroEstadoValidacion filtro) {
    final actual = state;
    if (isClosed || actual is! EstadoValidacionCargado) return;
    emit(EstadoValidacionCargado(actual.reportes, filtro: filtro));
  }
}
