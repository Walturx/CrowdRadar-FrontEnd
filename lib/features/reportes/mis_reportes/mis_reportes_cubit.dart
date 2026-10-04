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

  /// Bumped when a [cargar] replaces the list; a "load more" that started
  /// before it is stale (it would append to a list that was just replaced) and
  /// is discarded. A refresh that fails replaces nothing, so it does not bump.
  int _epoca = 0;

  bool _cargando = false;
  bool _cargandoMas = false;

  /// A load while another load is in flight is ignored; one that arrives
  /// during a "load more" supersedes it. A refresh over a loaded list keeps it
  /// visible until the new data arrives.
  Future<void> cargar() async {
    if (isClosed || _cargando) return;
    _cargando = true;
    final epoca = _epoca;
    final actual = state;
    if (actual is! MisReportesCargado) emit(const MisReportesCargando());
    try {
      final pagina = await _repositorio.listarMios(page: 1, size: _size);
      if (isClosed || epoca != _epoca) return;
      _epoca++;
      _pagina = pagina.page;
      emit(
        pagina.items.isEmpty
            ? const MisReportesVacio()
            : MisReportesCargado(pagina.items, hayMas: pagina.hayMas),
      );
    } catch (e) {
      if (isClosed) return;
      // Judge by the current state: a load more may have landed meanwhile.
      final ahora = state;
      emit(
        ahora is MisReportesCargado
            ? MisReportesCargado(
                ahora.reportes,
                hayMas: ahora.hayMas,
                cargandoMas: ahora.cargandoMas,
                errorMas: ahora.errorMas,
                errorActualizacion: mensajeDeError(e),
              )
            : MisReportesError(
                mensajeDeError(e),
                codigo: codigoDeError(e),
                esSinConexion: esErrorSinConexion(e),
              ),
      );
    } finally {
      _cargando = false;
    }
  }

  Future<void> cargarMas() async {
    final actual = state;
    if (isClosed ||
        _cargando ||
        _cargandoMas ||
        actual is! MisReportesCargado ||
        !actual.hayMas) {
      return;
    }
    _cargandoMas = true;
    final epoca = _epoca;
    emit(MisReportesCargado(actual.reportes, hayMas: true, cargandoMas: true));
    try {
      final pagina = await _repositorio.listarMios(
        page: _pagina + 1,
        size: _size,
      );
      if (isClosed || epoca != _epoca) return;
      _pagina = pagina.page;
      final vistos = {for (final r in actual.reportes) r.id};
      final todos = <ReporteSaturacion>[
        ...actual.reportes,
        for (final r in pagina.items)
          if (vistos.add(r.id)) r,
      ];
      // An empty page ends the list even if the server still claims more.
      emit(
        MisReportesCargado(
          todos,
          hayMas: pagina.hayMas && pagina.items.isNotEmpty,
        ),
      );
    } catch (e) {
      if (isClosed || epoca != _epoca) return;
      emit(
        MisReportesCargado(
          actual.reportes,
          hayMas: true,
          errorMas: mensajeDeError(e),
        ),
      );
    } finally {
      _cargandoMas = false;
    }
  }
}
