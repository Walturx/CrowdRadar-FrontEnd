import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/moderacion.dart';
import '../../../core/utils/mensaje_error.dart';
import '../data/moderacion_repository.dart';
import 'revision_reporte_state.dart';

/// HU 7.1 c2 / c3: one reported report and the admin's decision on it.
class RevisionReporteCubit extends Cubit<RevisionReporteState> {
  static const int comentarioMaximo = 280;
  static const String mensajeComentarioLargo =
      'El comentario no puede superar los $comentarioMaximo caracteres.';

  /// Codes that mean there is nothing (left) to review.
  static const Set<String> _codigosObsoletos = {
    'SIN_DENUNCIAS_PENDIENTES',
    'REPORTE_NO_ENCONTRADO',
  };

  final ModeracionRepository _repositorio;
  final int reporteId;

  RevisionReporteCubit(this._repositorio, this.reporteId)
    : super(const RevisionReporteCargando());

  Future<void> cargar() async {
    if (isClosed) return;
    emit(const RevisionReporteCargando());
    try {
      final detalle = await _repositorio.reporteDenunciado(reporteId);
      if (isClosed) return;
      emit(RevisionReporteCargado(detalle: detalle));
    } catch (e) {
      if (isClosed) return;
      emit(_fallo(e));
    }
  }

  /// Sends the decision. A failure rolls back to the buttons with a notice.
  Future<void> resolver(
    DecisionModeracion decision, {
    String? comentario,
  }) async {
    final actual = state;
    if (isClosed || actual is! RevisionReporteCargado || actual.resolviendo) {
      return;
    }
    final texto = comentario?.trim();
    if (texto != null && texto.length > comentarioMaximo) {
      emit(
        RevisionReporteCargado(
          detalle: actual.detalle,
          aviso: mensajeComentarioLargo,
        ),
      );
      return;
    }
    emit(RevisionReporteCargado(detalle: actual.detalle, resolviendo: true));
    try {
      final resolucion = await _repositorio.resolver(
        reporteId,
        decision,
        comentario: texto,
      );
      if (isClosed) return;
      emit(
        RevisionReporteResuelta(
          detalle: actual.detalle,
          resolucion: resolucion,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        _codigosObsoletos.contains(codigoDeError(e))
            ? RevisionReporteObsoleta(mensajeDeError(e))
            : RevisionReporteCargado(
                detalle: actual.detalle,
                aviso: mensajeDeError(e),
              ),
      );
    }
  }

  void descartarAviso() {
    final actual = state;
    if (isClosed || actual is! RevisionReporteCargado || actual.aviso == null) {
      return;
    }
    emit(RevisionReporteCargado(detalle: actual.detalle));
  }

  RevisionReporteState _fallo(Object e) =>
      codigoDeError(e) == 'REPORTE_NO_ENCONTRADO'
      ? RevisionReporteObsoleta(mensajeDeError(e))
      : RevisionReporteError(
          mensajeDeError(e),
          codigo: codigoDeError(e),
          esSinConexion: esErrorSinConexion(e),
        );
}
