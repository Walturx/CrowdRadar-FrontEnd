import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/mensaje_error.dart';
import '../data/moderacion_repository.dart';
import 'denunciados_state.dart';

/// HU 7.1: queue of reports with pending denuncias, newest first.
class DenunciadosCubit extends Cubit<DenunciadosState> {
  static const int tamanoPagina = 20;

  final ModeracionRepository _repositorio;

  DenunciadosCubit(this._repositorio) : super(const DenunciadosCargando());

  bool _cargando = false;
  bool _cargandoMas = false;

  Future<void> cargar() async {
    if (isClosed || _cargando) return;
    _cargando = true;
    if (state is! DenunciadosCargado) emit(const DenunciadosCargando());
    try {
      final pagina = await _repositorio.reportesDenunciados(
        page: 1,
        size: tamanoPagina,
      );
      if (isClosed) return;
      emit(
        DenunciadosCargado(
          reportes: pagina.items,
          total: pagina.total,
          page: pagina.page,
          hayMas: pagina.hayMas,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      final ahora = state;
      emit(
        ahora is DenunciadosCargado
            ? ahora.copiar(aviso: mensajeDeError(e))
            : DenunciadosError(
                mensajeDeError(e),
                codigo: codigoDeError(e),
                esSinConexion: esErrorSinConexion(e),
              ),
      );
    } finally {
      _cargando = false;
    }
  }

  /// Reloads keeping the list on screen (after a review).
  Future<void> refrescar() => cargar();

  /// The report was resolved (or is gone): it leaves the queue at once.
  void retirar(int reporteId) {
    final actual = state;
    if (isClosed || actual is! DenunciadosCargado) return;
    final quedan = [
      for (final r in actual.reportes)
        if (r.reporteId != reporteId) r,
    ];
    if (quedan.length == actual.reportes.length) return;
    emit(
      actual.copiar(
        reportes: quedan,
        total: actual.total > 0 ? actual.total - 1 : 0,
      ),
    );
  }

  Future<void> cargarMas() async {
    final actual = state;
    if (isClosed ||
        _cargando ||
        _cargandoMas ||
        actual is! DenunciadosCargado ||
        !actual.hayMas) {
      return;
    }
    _cargandoMas = true;
    emit(actual.copiar(cargandoMas: true));
    try {
      final pagina = await _repositorio.reportesDenunciados(
        page: actual.page + 1,
        size: tamanoPagina,
      );
      if (isClosed) return;
      final ahora = state;
      if (ahora is! DenunciadosCargado) return;
      final conocidos = {for (final r in ahora.reportes) r.reporteId};
      emit(
        ahora.copiar(
          reportes: [
            ...ahora.reportes,
            for (final r in pagina.items)
              if (!conocidos.contains(r.reporteId)) r,
          ],
          page: pagina.page,
          hayMas: pagina.hayMas,
          cargandoMas: false,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      final ahora = state;
      if (ahora is DenunciadosCargado) {
        emit(ahora.copiar(cargandoMas: false, aviso: mensajeDeError(e)));
      }
    } finally {
      _cargandoMas = false;
    }
  }

  void descartarAviso() {
    final actual = state;
    if (isClosed || actual is! DenunciadosCargado || actual.aviso == null) {
      return;
    }
    emit(actual.copiar(sinAviso: true));
  }
}
