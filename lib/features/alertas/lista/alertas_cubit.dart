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

  /// Minimum time between the automatic refreshes on returning to the app.
  static const Duration intervaloRefresco = Duration(seconds: 30);

  final DateTime Function() _reloj;

  AlertasCubit(this._repositorio, {DateTime Function()? reloj})
    : _reloj = reloj ?? DateTime.now,
      super(const AlertasCargando());

  /// When the last load or refresh finished (whatever its result).
  DateTime? _ultimaCarga;

  /// The first load failed: there is no count to show (the badge stays empty).
  bool get errorCarga => state is AlertasError;

  /// A load while another is in flight is ignored.
  bool _enVuelo = false;

  /// Alerts whose read mark is on its way to the server.
  final Set<int> _marcando = {};

  /// Alerts marked since the running reload started (the server may have
  /// answered before seeing them).
  final Set<int> _marcadasEnRefresco = {};

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
      _ultimaCarga = _reloj();
    }
  }

  /// The app came back to the foreground (or the list was opened): reloads in
  /// the background, keeping the alerts on screen and only adding a soft error
  /// when it fails. Marks made while it ran are kept over the fresh list.
  /// Without alerts it is a regular [cargar].
  Future<void> refrescar() async {
    final actual = state;
    if (actual is! AlertasCargado) return cargar();
    if (isClosed || _enVuelo) return;
    _enVuelo = true;
    // Clears a previous soft error so a repeated failure is reported again.
    emit(_conError(actual, null));
    _marcadasEnRefresco.clear();
    try {
      final nuevo = _conMarcasPendientes(await _leer());
      if (isClosed) return;
      emit(nuevo);
    } catch (e) {
      final ahora = state;
      if (isClosed || ahora is! AlertasCargado) return;
      emit(_conError(ahora, mensajeDeError(e)));
    } finally {
      _enVuelo = false;
      _ultimaCarga = _reloj();
    }
  }

  /// The app returned to the foreground: refreshes unless it did so less than
  /// [intervaloRefresco] ago. Without data (a failed first load) it retries.
  Future<void> alVolverAPrimerPlano() {
    final ultima = _ultimaCarga;
    if (state is AlertasCargado &&
        ultima != null &&
        _reloj().difference(ultima) < intervaloRefresco) {
      return Future.value();
    }
    return refrescar();
  }

  /// Marks one alert as read: the list and the counter change at once and are
  /// restored if the server refuses (a 404 means it is gone, so it stays read).
  Future<void> marcarLeida(int id) async {
    final actual = state;
    if (actual is! AlertasCargado) return;
    final alerta = actual.alertas.where((a) => a.id == id);
    if (alerta.isEmpty || alerta.first.leida || !_marcando.add(id)) return;
    emit(_cambiar(actual, id, leida: true));
    _marcadasEnRefresco.add(id);
    try {
      await _repositorio.marcarLeida(id);
    } on ApiException catch (e) {
      if (e.code != _codigoNoEncontrada) _restaurar(id, mensajeDeError(e));
    } catch (e) {
      _restaurar(id, mensajeDeError(e));
    } finally {
      _marcando.remove(id);
    }
  }

  /// Puts back the unread mark of [id] only if the list still shows it read,
  /// so the counter never drifts from what the list says.
  void _restaurar(int id, String error) {
    _marcadasEnRefresco.remove(id);
    final ahora = state;
    if (isClosed || ahora is! AlertasCargado) return;
    final alerta = ahora.alertas.where((a) => a.id == id);
    if (alerta.isEmpty || !alerta.first.leida) {
      emit(_conError(ahora, error));
      return;
    }
    emit(_conError(_cambiar(ahora, id, leida: false), error));
  }

  /// A fresh list the server computed before it saw the marks in flight: those
  /// alerts stay read and leave the unread counter.
  AlertasCargado _conMarcasPendientes(AlertasCargado nuevo) {
    var resultado = nuevo;
    for (final id in {..._marcando, ..._marcadasEnRefresco}) {
      final alerta = resultado.alertas.where((a) => a.id == id);
      if (alerta.isNotEmpty && !alerta.first.leida) {
        resultado = _cambiar(resultado, id, leida: true);
      }
    }
    return resultado;
  }

  static AlertasCargado _conError(AlertasCargado e, String? error) =>
      AlertasCargado(
        e.alertas,
        noLeidas: e.noLeidas,
        mensajeVacio: e.mensajeVacio,
        error: error,
      );

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
