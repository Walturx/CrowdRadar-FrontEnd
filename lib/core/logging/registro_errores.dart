import 'package:flutter/foundation.dart';

/// Strategy: injectable sink for errors that are handled but worth seeing.
abstract class RegistroErrores {
  void registrar(String contexto, Object error, [StackTrace? pila]);
}

/// Default sink: prints to the debug console (never the token or password).
class RegistroErroresConsola implements RegistroErrores {
  const RegistroErroresConsola();

  @override
  void registrar(String contexto, Object error, [StackTrace? pila]) =>
      debugPrint('[$contexto] ${error.runtimeType}: $error');
}
