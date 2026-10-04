import 'dart:async';

import 'package:flutter/foundation.dart';

import 'receptor_push.dart';

/// Null Object pattern, development flavor (used with `USAR_FAKES`): a
/// [ReceptorPush] that hands out a fixed fake token and lets code simulate a
/// notification tap with [simularApertura]. Real delivery (FCM) is not part of
/// this build; the in-app alert list is the guaranteed channel.
class ReceptorPushConsola implements ReceptorPush {
  static const String tokenDesarrollo = 'consola-dev-token';

  final StreamController<int> _toques = StreamController<int>.broadcast();

  @override
  Future<void> inicializar() async {
    debugPrint('[ReceptorPushConsola] listo (sin entrega real)');
  }

  @override
  Future<String?> obtenerToken() async => tokenDesarrollo;

  @override
  Stream<int> get lugarAbierto => _toques.stream;

  /// Behaves as if the user had tapped a notification about [lugarId].
  void simularApertura(int lugarId) {
    debugPrint('[ReceptorPushConsola] toque en notificación del lugar $lugarId');
    _toques.add(lugarId);
  }
}
