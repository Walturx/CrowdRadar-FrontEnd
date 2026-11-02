import 'package:crowdradar/core/utils/contador.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the singular only for exactly one', () {
    expect(
      contador(1, 'REPORTE POR REVISAR', 'REPORTES POR REVISAR'),
      '1 REPORTE POR REVISAR',
    );
    expect(contador(1, 'COINCIDENCIA', 'COINCIDENCIAS'), '1 COINCIDENCIA');
  });

  test('uses the plural for zero and for more than one', () {
    expect(contador(0, 'USUARIO', 'USUARIOS'), '0 USUARIOS');
    expect(
      contador(2, 'CUENTA SUSPENDIDA', 'CUENTAS SUSPENDIDAS'),
      '2 CUENTAS SUSPENDIDAS',
    );
  });
}
