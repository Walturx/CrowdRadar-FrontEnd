import 'dart:convert';

import 'package:crowdradar/core/session/usuario_sesion.dart';
import 'package:crowdradar/core/storage/memoria_token_storage.dart';

/// Unsigned JWT-shaped token with the given expiry.
String jwtFalso({required DateTime exp}) {
  String parte(Object o) =>
      base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  final segundos = exp.millisecondsSinceEpoch ~/ 1000;
  return '${parte({'alg': 'HS256'})}.${parte({'exp': segundos})}.firma';
}

const usuarioPrueba = UsuarioSesion(
  id: 1,
  nombre: 'Ana',
  apellido: 'Paz',
  email: 'ana@test.com',
  rol: 'USUARIO',
  status: 'ACTIVO',
);

const adminPrueba = UsuarioSesion(
  id: 2,
  nombre: 'Root',
  apellido: 'Admin',
  email: 'root@test.com',
  rol: 'ADMIN',
  status: 'ACTIVO',
);

/// Storage whose reads fail (S4.5).
class StorageQueFalla extends MemoriaTokenStorage {
  @override
  Future<String?> leerToken() async => throw StateError('keystore');
}
