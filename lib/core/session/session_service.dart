import 'dart:async';

import 'package:flutter/foundation.dart';

import '../errors/excepcion_con_mensaje.dart';
import '../logging/registro_errores.dart';
import '../storage/memoria_token_storage.dart';
import '../storage/token_storage.dart';
import 'jwt_util.dart';
import 'motivo_cierre.dart';
import 'usuario_sesion.dart';

sealed class EventoSesion {
  const EventoSesion();
}

class SesionIniciada extends EventoSesion {
  final UsuarioSesion usuario;

  const SesionIniciada(this.usuario);
}

class SesionCerrada extends EventoSesion {
  final MotivoCierre motivo;

  const SesionCerrada(this.motivo);
}

/// The session could not be persisted, so it was not started.
class ErrorAlmacenamientoSesion implements ExcepcionConMensaje {
  final Object causa;

  const ErrorAlmacenamientoSesion(this.causa);

  @override
  String get mensajeUsuario => 'No se pudo guardar la sesión en el dispositivo';

  @override
  String toString() => mensajeUsuario;
}

/// Singleton + Observer subject: owns the active session (token + user), its
/// persistence, and broadcasts [EventoSesion]s.
class SessionService {
  SessionService._();

  static final SessionService instance = SessionService._();

  /// Maximum time the first frame waits for secure storage.
  static const Duration timeoutRestaurarPorDefecto = Duration(seconds: 3);

  TokenStorage _storage = MemoriaTokenStorage();
  RegistroErrores _registro = const RegistroErroresConsola();
  Duration _timeoutRestaurar = timeoutRestaurarPorDefecto;
  DateTime Function() _reloj = DateTime.now;
  StreamController<EventoSesion> _eventos = StreamController.broadcast();
  /// Bumped by every restore; a read that finishes under an older value is stale.
  int _generacionRestauracion = 0;
  String? _token;
  UsuarioSesion? _usuario;

  String? get token => _token;

  UsuarioSesion? get usuario => _usuario;

  Stream<EventoSesion> get eventos => _eventos.stream;

  void configurar(
    TokenStorage storage, {
    DateTime Function()? reloj,
    RegistroErrores? registro,
    Duration? timeoutRestaurar,
  }) {
    _storage = storage;
    _reloj = reloj ?? DateTime.now;
    _registro = registro ?? const RegistroErroresConsola();
    _timeoutRestaurar = timeoutRestaurar ?? timeoutRestaurarPorDefecto;
  }

  /// Loads the persisted session; invalid or expired data is wiped.
  /// Any failure or timeout means "no session" (reported, never thrown).
  Future<void> restaurar() async {
    final generacion = ++_generacionRestauracion;
    try {
      await _leerPersistida(generacion).timeout(_timeoutRestaurar);
    } catch (e, pila) {
      // Invalidate the read still running: its late result must be discarded.
      _generacionRestauracion++;
      _registro.registrar('SessionService.restaurar', e, pila);
      _token = null;
      _usuario = null;
    }
  }

  Future<void> _leerPersistida(int generacion) async {
    final token = await _storage.leerToken();
    final usuario = await _storage.leerUsuario();
    if (generacion != _generacionRestauracion) return;
    if (token == null ||
        usuario == null ||
        JwtUtil.estaExpirado(token, ahora: _reloj())) {
      await _storage.borrar();
      return;
    }
    _token = token;
    _usuario = usuario;
  }

  /// Persists first; on failure nothing changes and
  /// [ErrorAlmacenamientoSesion] is thrown.
  Future<void> iniciar(String token, UsuarioSesion usuario) async {
    try {
      await _storage.guardar(token, usuario);
    } catch (e, pila) {
      _registro.registrar('SessionService.iniciar', e, pila);
      throw ErrorAlmacenamientoSesion(e);
    }
    _token = token;
    _usuario = usuario;
    _eventos.add(SesionIniciada(usuario));
  }

  Future<void> actualizarUsuario(UsuarioSesion usuario) async {
    final token = _token;
    if (token == null) return;
    await _storage.guardar(token, usuario);
    _usuario = usuario;
  }

  /// Memory is cleared and [SesionCerrada] is always emitted; a storage
  /// failure is reported but must never keep the app authenticated.
  Future<void> cerrar(MotivoCierre motivo) async {
    _token = null;
    _usuario = null;
    try {
      await _storage.borrar();
    } catch (e, pila) {
      _registro.registrar('SessionService.cerrar', e, pila);
    } finally {
      _eventos.add(SesionCerrada(motivo));
    }
  }

  /// Like [cerrar] but ignored when there is no active session.
  Future<void> expirar(MotivoCierre motivo) async {
    if (_token == null) return;
    await cerrar(motivo);
  }

  @visibleForTesting
  void reiniciar() {
    _generacionRestauracion++;
    _token = null;
    _usuario = null;
    _storage = MemoriaTokenStorage();
    _reloj = DateTime.now;
    _registro = const RegistroErroresConsola();
    _timeoutRestaurar = timeoutRestaurarPorDefecto;
    _eventos.close();
    _eventos = StreamController.broadcast();
  }
}
