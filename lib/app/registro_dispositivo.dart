import 'package:flutter/foundation.dart';

import '../core/logging/registro_errores.dart';
import '../core/push/receptor_push.dart';
import '../features/alertas/data/alerta_repository.dart';

/// Keeps the backend informed of this device's push token: registered when the
/// user signs in, removed when they sign out. Both are best effort: a failure
/// is logged and never blocks the sign in or out, and without a token (push
/// unavailable) nothing happens.
class RegistroDispositivo {
  final ReceptorPush _receptor;
  final AlertaRepository _alertas;
  final PlataformaPush _plataforma;
  final RegistroErrores _registro;

  String? _tokenRegistrado;

  RegistroDispositivo({
    required ReceptorPush receptor,
    required AlertaRepository alertas,
    PlataformaPush? plataforma,
    RegistroErrores registro = const RegistroErroresConsola(),
  }) : _receptor = receptor,
       _alertas = alertas,
       _plataforma = plataforma ?? _plataformaActual(),
       _registro = registro;

  static PlataformaPush _plataformaActual() =>
      defaultTargetPlatform == TargetPlatform.iOS
      ? PlataformaPush.ios
      : PlataformaPush.android;

  Future<void> registrar() async {
    try {
      final token = await _receptor.obtenerToken();
      if (token == null) return;
      await _alertas.registrarDispositivo(token, _plataforma);
      _tokenRegistrado = token;
    } catch (e, pila) {
      _registro.registrar('RegistroDispositivo.registrar', e, pila);
    }
  }

  /// Must run while the session is still valid (the DELETE is authenticated).
  Future<void> quitar() async {
    final token = _tokenRegistrado;
    if (token == null) return;
    _tokenRegistrado = null;
    try {
      await _alertas.eliminarDispositivo(token);
    } catch (e, pila) {
      _registro.registrar('RegistroDispositivo.quitar', e, pila);
    }
  }
}
