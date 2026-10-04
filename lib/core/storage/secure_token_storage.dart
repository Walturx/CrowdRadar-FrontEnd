import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../session/usuario_sesion.dart';
import 'token_storage.dart';

/// Keystore/Keychain-backed storage.
class SecureTokenStorage implements TokenStorage {
  static const String claveToken = 'crowdradar.jwt';
  static const String claveUsuario = 'crowdradar.usuario';

  final FlutterSecureStorage _storage;

  SecureTokenStorage(this._storage);

  @override
  Future<String?> leerToken() => _storage.read(key: claveToken);

  @override
  Future<UsuarioSesion?> leerUsuario() async {
    final json = await _storage.read(key: claveUsuario);
    if (json == null) return null;
    try {
      return UsuarioSesion.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      // Corrupt stored user: treat as absent so restore wipes the session.
      return null;
    }
  }

  @override
  Future<void> guardar(String token, UsuarioSesion usuario) async {
    await _storage.write(key: claveToken, value: token);
    await _storage.write(
      key: claveUsuario,
      value: jsonEncode(usuario.toJson()),
    );
  }

  @override
  Future<void> borrar() async {
    await _storage.delete(key: claveToken);
    await _storage.delete(key: claveUsuario);
  }
}
