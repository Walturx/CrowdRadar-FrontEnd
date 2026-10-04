import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/validacion.dart';
import '../../../core/utils/mensaje_error.dart';
import '../data/validacion_repository.dart';
import 'detalle_reporte_state.dart';

/// HU 5.1 c2 / 5.2: one report with its reliability and my vote.
class DetalleReporteCubit extends Cubit<DetalleState> {
  /// HU 5.1 c3.
  static const String mensajeYaParticipo =
      'Ya participaste en la validación de este reporte.';

  final ValidacionRepository _repositorio;
  final int _reporteId;

  DetalleReporteCubit(this._repositorio, this._reporteId)
    : super(const DetalleCargando());

  bool _cargando = false;

  Future<void> cargar() async {
    if (isClosed || _cargando) return;
    _cargando = true;
    try {
      final detalle = await _repositorio.obtenerReporte(_reporteId);
      if (!isClosed) emit(DetalleCargado(detalle));
    } catch (e) {
      if (isClosed) return;
      final actual = state;
      emit(
        actual is DetalleCargado
            ? DetalleCargado(actual.detalle, aviso: mensajeDeError(e))
            : DetalleError(
                mensajeDeError(e),
                codigo: codigoDeError(e),
                esSinConexion: esErrorSinConexion(e),
              ),
      );
    } finally {
      _cargando = false;
    }
  }

  /// Own reports and reports already voted cannot be voted again.
  Future<void> validar(TipoAccionValidacion accion) async {
    final actual = state;
    if (isClosed ||
        actual is! DetalleCargado ||
        actual.votando ||
        actual.detalle.esPropio ||
        actual.detalle.miValidacion != null) {
      return;
    }
    emit(DetalleCargado(actual.detalle, votando: true));
    try {
      final voto = await _repositorio.validar(_reporteId, accion);
      if (isClosed) return;
      emit(
        DetalleCargado(
          actual.detalle.copyWith(
            miValidacion: accion,
            confiabilidad: voto.confiabilidad,
            estadoValidacion: voto.estadoValidacion,
          ),
          aviso: '¡Gracias por validar! +${voto.puntosGanados} karma',
        ),
      );
    } catch (e) {
      if (isClosed) return;
      final duplicado = codigoDeError(e) == 'VALIDACION_DUPLICADA';
      emit(
        DetalleCargado(
          actual.detalle,
          aviso: duplicado ? mensajeYaParticipo : mensajeDeError(e),
        ),
      );
      if (duplicado) {
        // Show the vote the server holds, keeping the notice.
        await cargar();
        final ahora = state;
        if (!isClosed && ahora is DetalleCargado) {
          emit(DetalleCargado(ahora.detalle, aviso: mensajeYaParticipo));
        }
      }
    }
  }

  void descartarAviso() {
    final actual = state;
    if (isClosed || actual is! DetalleCargado || actual.aviso == null) return;
    emit(DetalleCargado(actual.detalle, votando: actual.votando));
  }
}
