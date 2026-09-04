import 'package:crowdradar/core/logging/registro_errores.dart';

/// Collects reported errors so tests can assert on them.
class RegistroFalso implements RegistroErrores {
  final List<({String contexto, Object error})> registros = [];

  @override
  void registrar(String contexto, Object error, [StackTrace? pila]) =>
      registros.add((contexto: contexto, error: error));
}
