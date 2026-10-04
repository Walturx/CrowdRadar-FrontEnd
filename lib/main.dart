import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app/arranque.dart';
import 'app/dependencias.dart';
import 'core/config/entorno.dart';
import 'core/logging/registro_errores.dart';
import 'core/session/session_service.dart';
import 'core/storage/secure_token_storage.dart';

/// Only place besides [Dependencias] allowed to touch `SessionService.instance`.
Future<Dependencias> _iniciar() async {
  final entorno = Entorno.desdeDartDefine();
  final sesion = SessionService.instance
    ..configurar(SecureTokenStorage(const FlutterSecureStorage()));
  await sesion.restaurar();
  return Dependencias.crear(entorno, sesion);
}

void main() {
  const registro = RegistroErroresConsola();
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(const ArranqueApp(iniciar: _iniciar, registro: registro));
  }, (error, pila) => registro.registrar('zona', error, pila));
}
