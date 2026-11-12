import 'dart:async';

import 'package:crowdradar/core/push/receptor_push.dart';
import 'package:flutter/foundation.dart';

/// Test double for [ReceptorPush]: hands out a fixed fake token and lets a
/// test simulate a notification tap with [simularApertura] and a message
/// received in the foreground with [simularMensaje]. Production uses
/// ReceptorPushFcm; the in-app alert list stays the guaranteed
/// channel.
class ReceptorPushConsola implements ReceptorPush {
  static const String tokenDesarrollo = 'consola-dev-token';

  final StreamController<int> _toques = StreamController<int>.broadcast();
  final StreamController<MensajePrimerPlano> _mensajes =
      StreamController<MensajePrimerPlano>.broadcast();

  @override
  Future<void> inicializar() async {
    debugPrint('[ReceptorPushConsola] listo (sin entrega real)');
  }

  @override
  Future<String?> obtenerToken() async => tokenDesarrollo;

  @override
  Stream<int> get lugarAbierto => _toques.stream;

  @override
  Stream<MensajePrimerPlano> get mensajesEnPrimerPlano => _mensajes.stream;

  /// Behaves as if the user had tapped a notification about [lugarId].
  void simularApertura(int lugarId) {
    debugPrint(
      '[ReceptorPushConsola] toque en notificación del lugar $lugarId',
    );
    _toques.add(lugarId);
  }

  /// Behaves as if [mensaje] had arrived with the app in the foreground.
  void simularMensaje(MensajePrimerPlano mensaje) {
    debugPrint(
      '[ReceptorPushConsola] mensaje en primer plano: ${mensaje.titulo}',
    );
    _mensajes.add(mensaje);
  }
}
