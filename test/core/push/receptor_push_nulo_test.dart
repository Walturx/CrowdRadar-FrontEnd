import 'package:crowdradar/core/push/receptor_push.dart';
import 'package:crowdradar/core/push/receptor_push_nulo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final ReceptorPush receptor = ReceptorPushNulo();

  test('inicializar completes without side effects', () async {
    await expectLater(receptor.inicializar(), completes);
  });

  test('obtenerToken yields no token', () async {
    expect(await receptor.obtenerToken(), isNull);
  });

  test('lugarAbierto never emits and is usable more than once', () async {
    expect(await receptor.lugarAbierto.isEmpty, isTrue);
    expect(await receptor.lugarAbierto.isEmpty, isTrue);
  });
}
