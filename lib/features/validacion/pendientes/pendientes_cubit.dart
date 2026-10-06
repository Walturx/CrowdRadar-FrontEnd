import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/map/centro_compartido.dart';
import '../../../core/models/validacion.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/mensaje_error.dart';
import '../data/validacion_repository.dart';
import 'pendientes_state.dart';

/// HU 5.1: reports around the map centre waiting for the user's vote.
class PendientesCubit extends Cubit<PendientesState> {
  /// HU 5.1 c3.
  static const String mensajeYaParticipo =
      'Ya participaste en la validación de este reporte.';

  final ValidacionRepository _repositorio;
  final CentroMapaCompartido _centro;

  PendientesCubit(this._repositorio, this._centro)
    : super(const PendientesCargando());

  bool _cargando = false;

  Future<void> cargar() async {
    if (isClosed || _cargando) return;
    _cargando = true;
    final actual = state;
    if (actual is! PendientesCargado) emit(const PendientesCargando());
    try {
      final centro = _centro.actual;
      final pagina = await _repositorio.pendientes(
        lat: centro.latitud,
        lng: centro.longitud,
      );
      if (isClosed) return;
      emit(PendientesCargado(reportes: pagina.items));
    } catch (e) {
      if (isClosed) return;
      final ahora = state;
      emit(
        ahora is PendientesCargado
            ? _con(ahora, aviso: mensajeDeError(e))
            : PendientesError(
                mensajeDeError(e),
                codigo: codigoDeError(e),
                esSinConexion: esErrorSinConexion(e),
              ),
      );
    } finally {
      _cargando = false;
    }
  }

  /// Optimistic: the report leaves the list at once. A failure puts it back; a
  /// 404 / 409 / 422 means it can no longer be voted, so it stays removed.
  Future<void> votar(
    ReportePendiente reporte,
    TipoAccionValidacion accion,
  ) async {
    final actual = state;
    if (isClosed || actual is! PendientesCargado) return;
    final posicion = actual.reportes.indexWhere((r) => r.id == reporte.id);
    if (posicion < 0 || actual.votando.contains(reporte.id)) return;
    emit(
      PendientesCargado(
        reportes: [...actual.reportes]..removeAt(posicion),
        votando: {...actual.votando, reporte.id},
        ultimoVoto: actual.ultimoVoto,
      ),
    );
    try {
      final voto = await _repositorio.validar(reporte.id, accion);
      _terminar(
        reporte.id,
        ultimoVoto: VotoRegistrado(
          reporte: reporte,
          accion: accion,
          puntosGanados: voto.puntosGanados,
        ),
      );
    } on ApiException catch (e) {
      final definitivo = const {404, 409, 422}.contains(e.status);
      _terminar(
        reporte.id,
        aviso: e.code == 'VALIDACION_DUPLICADA'
            ? mensajeYaParticipo
            : mensajeDeError(e),
        devolver: definitivo ? null : (reporte, posicion),
      );
    } catch (e) {
      _terminar(
        reporte.id,
        aviso: mensajeDeError(e),
        devolver: (reporte, posicion),
      );
    }
  }

  void descartarAviso() {
    final actual = state;
    if (isClosed || actual is! PendientesCargado || actual.aviso == null) {
      return;
    }
    emit(
      PendientesCargado(
        reportes: actual.reportes,
        votando: actual.votando,
        ultimoVoto: actual.ultimoVoto,
      ),
    );
  }

  void _terminar(
    int id, {
    VotoRegistrado? ultimoVoto,
    String? aviso,
    (ReportePendiente, int)? devolver,
  }) {
    final actual = state;
    if (isClosed || actual is! PendientesCargado) return;
    final reportes = [...actual.reportes];
    if (devolver != null) {
      reportes.insert(devolver.$2.clamp(0, reportes.length), devolver.$1);
    }
    emit(
      PendientesCargado(
        reportes: reportes,
        votando: {...actual.votando}..remove(id),
        ultimoVoto: ultimoVoto ?? actual.ultimoVoto,
        aviso: aviso,
      ),
    );
  }

  PendientesCargado _con(PendientesCargado s, {String? aviso}) =>
      PendientesCargado(
        reportes: s.reportes,
        votando: s.votando,
        ultimoVoto: s.ultimoVoto,
        aviso: aviso,
      );
}
