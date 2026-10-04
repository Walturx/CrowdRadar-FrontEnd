import 'dart:async';

import 'package:flutter/foundation.dart';

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

/// Singleton owning the active session (token + user) and its persistence.
class SessionService {
  SessionService._();

  static final SessionService instance = SessionService._();

  TokenStorage _storage = MemoriaTokenStorage();
  DateTime Function() _reloj = DateTime.now;
  StreamController<EventoSesion> _eventos = StreamController.broadcast();
  String? _token;
  UsuarioSesion? _usuario;

  String? get token => _token;

  UsuarioSesion? get usuario => _usuario;

  Stream<EventoSesion> get eventos => _eventos.stream;

  void configurar(TokenStorage storage, {DateTime Function()? reloj}) {
    _storage = storage;
    _reloj = reloj ?? DateTime.now;
  }

  /// Loads the persisted session; invalid or expired data is wiped.
  Future<void> restaurar() async {
    try {
      final token = await _storage.leerToken();
      final usuario = await _storage.leerUsuario();
      if (token == null ||
          usuario == null ||
          JwtUtil.estaExpirado(token, ahora: _reloj())) {
        await _storage.borrar();
        return;
      }
      _token = token;
      _usuario = usuario;
    } catch (_) {
      _token = null;
      _usuario = null;
    }
  }

  Future<void> iniciar(String token, UsuarioSesion usuario) async {
    _token = token;
    _usuario = usuario;
    await _storage.guardar(token, usuario);
    _eventos.add(SesionIniciada(usuario));
  }

  Future<void> actualizarUsuario(UsuarioSesion usuario) async {
    final token = _token;
    if (token == null) return;
    _usuario = usuario;
    await _storage.guardar(token, usuario);
  }

  Future<void> cerrar(MotivoCierre motivo) async {
    _token = null;
    _usuario = null;
    await _storage.borrar();
    _eventos.add(SesionCerrada(motivo));
  }

  /// Like [cerrar] but ignored when there is no active session.
  Future<void> expirar(MotivoCierre motivo) async {
    if (_token == null) return;
    await cerrar(motivo);
  }

  @visibleForTesting
  void reiniciar() {
    _token = null;
    _usuario = null;
    _storage = MemoriaTokenStorage();
    _reloj = DateTime.now;
    _eventos.close();
    _eventos = StreamController.broadcast();
  }
}
