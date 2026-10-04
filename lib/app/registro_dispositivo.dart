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

  /// The registration running right now; [quitar] waits for it.
  Future<void>? _registrando;

  /// The [quitar] running right now; a [registrar] waits for it so a DELETE
  /// landing after a new sign in cannot leave the device unregistered.
  Future<void>? _quitando;

  /// A DELETE failed: the backend may still hold [_tokenRegistrado].
  bool _borradoPendiente = false;

  /// Registers the token once: a call while another runs shares it, and a
  /// token the backend already has is not sent again. A DELETE that failed
  /// earlier is retried first.
  Future<void> registrar() => _registrando ??= _registrar().whenComplete(
    () => _registrando = null,
  );

  Future<void> _registrar() async {
    try {
      await _quitando;
      if (_borradoPendiente) await _reintentarBorrado();
      final token = await _receptor.obtenerToken();
      if (token == null || token == _tokenRegistrado) return;
      await _alertas.registrarDispositivo(token, _plataforma);
      _tokenRegistrado = token;
    } catch (e, pila) {
      _registro.registrar('RegistroDispositivo.registrar', e, pila);
    }
  }

  Future<void> _reintentarBorrado() async {
    final token = _tokenRegistrado;
    // One retry only: whatever happens, this sign in registers afresh.
    _borradoPendiente = false;
    _tokenRegistrado = null;
    if (token == null) return;
    try {
      await _alertas.eliminarDispositivo(token);
    } catch (e, pila) {
      _registro.registrar('RegistroDispositivo.reintento', e, pila);
    }
  }

  /// Waits for a registration in flight, then deletes the token. Must run
  /// while the session is still valid (the DELETE is authenticated); when it
  /// fails the token is kept and retried by the next [quitar] or [registrar].
  Future<void> quitar() =>
      _quitando = _quitar().whenComplete(() => _quitando = null);

  Future<void> _quitar() async {
    await _registrando;
    final token = _tokenRegistrado;
    if (token == null) return;
    try {
      await _alertas.eliminarDispositivo(token);
      _tokenRegistrado = null;
      _borradoPendiente = false;
    } catch (e, pila) {
      _borradoPendiente = true;
      _registro.registrar('RegistroDispositivo.quitar', e, pila);
    }
  }
}
