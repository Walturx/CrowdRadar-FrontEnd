import 'package:crowdradar/core/push/receptor_push.dart';
import 'package:crowdradar/core/push/receptor_push_consola.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('inicializar completes and the dev token is stable', () async {
    final ReceptorPush receptor = ReceptorPushConsola();

    await expectLater(receptor.inicializar(), completes);

    expect(await receptor.obtenerToken(), ReceptorPushConsola.tokenDesarrollo);
    expect(await receptor.obtenerToken(), ReceptorPushConsola.tokenDesarrollo);
  });

  test('simularApertura emits the place id to every listener', () async {
    final receptor = ReceptorPushConsola();
    final a = receptor.lugarAbierto.take(2).toList();
    final b = receptor.lugarAbierto.take(2).toList();

    receptor.simularApertura(4);
    receptor.simularApertura(9);

    expect(await a, [4, 9]);
    expect(await b, [4, 9]);
    await receptor.cerrar();
  });
}
