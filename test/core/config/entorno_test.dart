import 'dart:io';

import 'package:crowdradar/core/config/entorno.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the shown app version matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(r'^version:\s*([^+\s]+)', multiLine: true)
        .firstMatch(pubspec)!
        .group(1);

    expect(Entorno.version, version);
  });

  group('Entorno', () {
    test('S2.1 defaults without dart-define', () {
      final entorno = Entorno.desdeDartDefine();

      expect(entorno.apiUrl, 'http://10.0.2.2:3000');
      expect(entorno.usarFakes, isFalse);
    });

    test('S2.2 explicit values override defaults', () {
      const entorno = Entorno(apiUrl: 'http://x:1', usarFakes: true);

      expect(entorno.apiUrl, 'http://x:1');
      expect(entorno.usarFakes, isTrue);
    });
  });
}
