import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/nivel_saturacion.dart';
import '../../../core/utils/mensaje_error.dart';
import '../data/reporte_repository.dart';
import 'reportar_state.dart';

class ReportarCubit extends Cubit<ReportarState> {
  static const String mensajeGracias = '¡Gracias por reportar!';
  static const String mensajeSinNivel =
      'Selecciona un nivel de saturación para enviar tu reporte.';
  static const String mensajeEnEspera =
      'Ya enviaste un reporte para este lugar. Inténtalo más tarde.';
  static const String mensajeTopeDiario =
      'No se otorgaron puntos por este reporte (tope diario alcanzado).';
  static const String mensajeSinPuntos =
      'No se otorgaron puntos por este reporte.';

  static const String _codigoEnEspera = 'REPORTE_EN_ESPERA';
  static const String _motivoTopeDiario = 'TOPE_DIARIO';

  final ReporteRepository _repositorio;
  final int _lugarId;

  ReportarCubit(this._repositorio, this._lugarId)
    : super(const ReportarEditando());

  NivelSaturacion? _nivel;

  /// A submit while another is in flight is ignored.
  bool _enVuelo = false;

  void seleccionarNivel(NivelSaturacion nivel) {
    if (_enVuelo || state is ReportarEnviado) return;
    _nivel = nivel;
    emit(ReportarEditando(nivel: nivel));
  }

  Future<void> enviar() async {
    final nivel = _nivel;
    if (_enVuelo || state is ReportarEnviado) return;
    if (nivel == null) {
      emit(const ReportarEditando(error: mensajeSinNivel));
      return;
    }
    _enVuelo = true;
    emit(ReportarEnviando(nivel));
    try {
      final r = await _repositorio.reportar(_lugarId, nivel);
      emit(
        ReportarEnviado(
          mensaje: mensajeGracias,
          puntosGanados: r.puntosGanados,
          totalKarma: r.totalKarma,
          motivoSinPuntos: r.puntosGanados > 0
              ? null
              : (r.motivoSinPuntos == _motivoTopeDiario
                    ? mensajeTopeDiario
                    : mensajeSinPuntos),
        ),
      );
    } catch (e) {
      final codigo = codigoDeError(e);
      emit(
        ReportarFallido(
          codigo == _codigoEnEspera ? mensajeEnEspera : mensajeDeError(e),
          nivel: nivel,
          codigo: codigo,
          esSinConexion: esErrorSinConexion(e),
        ),
      );
    } finally {
      _enVuelo = false;
    }
  }
}
