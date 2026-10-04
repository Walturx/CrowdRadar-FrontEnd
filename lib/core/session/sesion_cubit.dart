import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'motivo_cierre.dart';
import 'sesion_state.dart';
import 'session_service.dart';

/// Observer: exposes the session to the UI and router by listening to
/// `SessionService.eventos`.
class SesionCubit extends Cubit<SesionState> {
  /// How long a sign out waits for the [antesDeCerrar] hook.
  static const Duration plazoAntesDeCerrar = Duration(seconds: 2);

  final SessionService _sesion;

  /// Runs while the session is still valid, right before a user-initiated
  /// sign out (e.g. to unregister the push device). Its failure is ignored and
  /// it is abandoned after [plazoAntesDeCerrar].
  final Future<void> Function()? _antesDeCerrar;
  late final StreamSubscription<EventoSesion> _suscripcion;

  SesionCubit(this._sesion, {Future<void> Function()? antesDeCerrar})
    : _antesDeCerrar = antesDeCerrar,
      super(_estadoInicial(_sesion)) {
    _suscripcion = _sesion.eventos.listen((evento) => emit(switch (evento) {
          SesionIniciada(:final usuario) =>
            SesionAutenticada(usuario: usuario, esAdmin: usuario.esAdmin),
          SesionCerrada(:final motivo) => SesionNoAutenticada(motivo: motivo),
        }));
  }

  static SesionState _estadoInicial(SessionService sesion) {
    final usuario = sesion.usuario;
    if (sesion.token == null || usuario == null) {
      return const SesionNoAutenticada();
    }
    return SesionAutenticada(usuario: usuario, esAdmin: usuario.esAdmin);
  }

  Future<void> cerrarSesion() async {
    try {
      await _antesDeCerrar?.call().timeout(plazoAntesDeCerrar);
    } catch (_) {
      // Best effort: signing out must never depend on it.
    }
    await _sesion.cerrar(MotivoCierre.usuario);
  }

  @override
  Future<void> close() {
    _suscripcion.cancel();
    return super.close();
  }
}
