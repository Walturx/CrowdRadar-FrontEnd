import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/alerta.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/mensaje_error.dart';
import '../data/alerta_repository.dart';
import 'alertas_state.dart';

/// HU 8.3: the user's saturation alerts and their unread count (the badge of
/// the Favoritos tab). One instance serves the whole signed-in shell.
class AlertasCubit extends Cubit<AlertasState> {
  static const String _codigoNoEncontrada = 'ALERTA_NO_ENCONTRADA';

  final AlertaRepository _repositorio;

  AlertasCubit(this._repositorio) : super(const AlertasCargando());

  /// A load while another is in flight is ignored.
  bool _enVuelo = false;

  /// Unread alerts; zero until the first successful load.
  int get noLeidas {
    final actual = state;
    return actual is AlertasCargado ? actual.noLeidas : 0;
  }

  Future<void> cargar() async {
    if (isClosed || _enVuelo) return;
    _enVuelo = true;
    emit(const AlertasCargando());
    try {
      final nuevo = await _leer();
      if (isClosed) return;
      emit(nuevo);
    } catch (e) {
      if (isClosed) return;
      emit(
        AlertasError(
          mensajeDeError(e),
          codigo: codigoDeError(e),
          esSinConexion: esErrorSinConexion(e),
        ),
      );
    } finally {
      _enVuelo = false;
    }
  }

  /// The app came back to the foreground (or the list was opened): reloads in
  /// the background, keeping the alerts on screen and only adding a soft error
  /// when it fails. Without alerts it is a regular [cargar].
  Future<void> alAbrirApp() async {
    final actual = state;
    if (actual is! AlertasCargado) return cargar();
    if (isClosed || _enVuelo) return;
    _enVuelo = true;
    // Clears a previous soft error so a repeated failure is reported again.
    emit(AlertasCargado(
      actual.alertas,
      noLeidas: actual.noLeidas,
      mensajeVacio: actual.mensajeVacio,
    ));
    try {
      final nuevo = await _leer();
      if (isClosed) return;
      emit(nuevo);
    } catch (e) {
      if (isClosed) return;
      emit(
        AlertasCargado(
          actual.alertas,
          noLeidas: actual.noLeidas,
          mensajeVacio: actual.mensajeVacio,
          error: mensajeDeError(e),
        ),
      );
    } finally {
      _enVuelo = false;
    }
  }

  /// Marks one alert as read: the list and the counter change at once and are
  /// restored if the server refuses (a 404 means it is gone, so it stays read).
  Future<void> marcarLeida(int id) async {
    final actual = state;
    if (actual is! AlertasCargado) return;
    final alerta = actual.alertas.where((a) => a.id == id);
    if (alerta.isEmpty || alerta.first.leida) return;
    emit(_cambiar(actual, id, leida: true));
    try {
      await _repositorio.marcarLeida(id);
    } on ApiException catch (e) {
      if (e.code != _codigoNoEncontrada) _restaurar(id, mensajeDeError(e));
    } catch (e) {
      _restaurar(id, mensajeDeError(e));
    }
  }

  void _restaurar(int id, String error) {
    final ahora = state;
    if (isClosed || ahora is! AlertasCargado) return;
    final cambiada = _cambiar(ahora, id, leida: false);
    emit(
      AlertasCargado(
        cambiada.alertas,
        noLeidas: cambiada.noLeidas,
        mensajeVacio: cambiada.mensajeVacio,
        error: error,
      ),
    );
  }

  Future<AlertasCargado> _leer() async {
    final res = await _repositorio.listar();
    final items = res.pagina.items;
    return AlertasCargado(
      [...items.where((a) => !a.leida), ...items.where((a) => a.leida)],
      noLeidas: res.noLeidas,
      mensajeVacio: res.mensaje,
    );
  }

  static AlertasCargado _cambiar(
    AlertasCargado estado,
    int id, {
    required bool leida,
  }) => AlertasCargado(
    [
      for (final a in estado.alertas)
        if (a.id == id) _conLeida(a, leida) else a,
    ],
    noLeidas: estado.noLeidas + (leida ? -1 : 1),
    mensajeVacio: estado.mensajeVacio,
  );

  static Alerta _conLeida(Alerta a, bool leida) => Alerta(
    id: a.id,
    lugarId: a.lugarId,
    lugarNombre: a.lugarNombre,
    nivelAnterior: a.nivelAnterior,
    nivelNuevo: a.nivelNuevo,
    mensaje: a.mensaje,
    leida: leida,
    fechaHora: a.fechaHora,
  );
}
