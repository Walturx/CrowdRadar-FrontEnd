import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/reporte_saturacion.dart';
import '../../../core/utils/mensaje_error.dart';
import '../data/reporte_repository.dart';
import 'mis_reportes_state.dart';

class MisReportesCubit extends Cubit<MisReportesState> {
  final ReporteRepository _repositorio;
  final int _size;

  MisReportesCubit(this._repositorio, {int size = 20})
    : _size = size,
      super(const MisReportesCargando());

  int _pagina = 1;

  /// A load while another is in flight is ignored.
  bool _enVuelo = false;

  Future<void> cargar() async {
    if (_enVuelo) return;
    _enVuelo = true;
    emit(const MisReportesCargando());
    try {
      final pagina = await _repositorio.listarMios(page: 1, size: _size);
      if (isClosed) return;
      _pagina = pagina.page;
      emit(
        pagina.items.isEmpty
            ? const MisReportesVacio()
            : MisReportesCargado(pagina.items, hayMas: pagina.hayMas),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        MisReportesError(
          mensajeDeError(e),
          codigo: codigoDeError(e),
          esSinConexion: esErrorSinConexion(e),
        ),
      );
    } finally {
      _enVuelo = false;
    }
  }

  Future<void> cargarMas() async {
    final actual = state;
    if (_enVuelo || actual is! MisReportesCargado || !actual.hayMas) return;
    _enVuelo = true;
    emit(MisReportesCargado(actual.reportes, hayMas: true, cargandoMas: true));
    try {
      final pagina = await _repositorio.listarMios(
        page: _pagina + 1,
        size: _size,
      );
      if (isClosed) return;
      _pagina = pagina.page;
      final todos = <ReporteSaturacion>[...actual.reportes, ...pagina.items];
      emit(MisReportesCargado(todos, hayMas: pagina.hayMas));
    } catch (e) {
      if (isClosed) return;
      emit(
        MisReportesCargado(
          actual.reportes,
          hayMas: true,
          errorMas: mensajeDeError(e),
        ),
      );
    } finally {
      _enVuelo = false;
    }
  }
}
