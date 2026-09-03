import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app/app.dart';
import 'app/dependencias.dart';
import 'core/config/entorno.dart';
import 'core/session/session_service.dart';
import 'core/storage/secure_token_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final entorno = Entorno.desdeDartDefine();
  final sesion = SessionService.instance
    ..configurar(SecureTokenStorage(const FlutterSecureStorage()));
  await sesion.restaurar();
  runApp(CrowdRadarApp(dependencias: Dependencias.crear(entorno, sesion)));
}
