import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'motivo_cierre.dart';
import 'sesion_state.dart';
import 'session_service.dart';

/// Exposes the session to the UI and router.
class SesionCubit extends Cubit<SesionState> {
  final SessionService _sesion;
  late final StreamSubscription<EventoSesion> _suscripcion;

  SesionCubit(this._sesion) : super(_estadoInicial(_sesion)) {
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

  /// Push-device cleanup is deferred to M1/M3.
  Future<void> cerrarSesion() => _sesion.cerrar(MotivoCierre.usuario);

  @override
  Future<void> close() {
    _suscripcion.cancel();
    return super.close();
  }
}
