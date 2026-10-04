import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/nivel_saturacion.dart';
import '../../../core/network/api_exception.dart';
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
    if (isClosed || _enVuelo || state is ReportarEnviado) return;
    _nivel = nivel;
    emit(ReportarEditando(nivel: nivel));
  }

  Future<void> enviar() async {
    final nivel = _nivel;
    if (isClosed || _enVuelo || state is ReportarEnviado) return;
    if (nivel == null) {
      emit(const ReportarEditando(error: mensajeSinNivel));
      return;
    }
    _enVuelo = true;
    emit(ReportarEnviando(nivel));
    try {
      final r = await _repositorio.reportar(_lugarId, nivel);
      if (isClosed) return;
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
      if (isClosed) return;
      final codigo = codigoDeError(e);
      final status = e is ApiException ? e.status : 0;
      final sinConexion = esErrorSinConexion(e);
      emit(
        ReportarFallido(
          codigo == _codigoEnEspera ? _mensajeEnEspera(e) : mensajeDeError(e),
          nivel: nivel,
          codigo: codigo,
          esSinConexion: sinConexion,
          bloqueante: status == 403 || status == 404,
          reintentable: sinConexion || status >= 500,
        ),
      );
    } finally {
      _enVuelo = false;
    }
  }

  /// The server text carries the minutes left; the static one is the fallback.
  static String _mensajeEnEspera(Object e) {
    final servidor = mensajeDeError(e).trim();
    return servidor.isEmpty ? mensajeEnEspera : servidor;
  }
}
