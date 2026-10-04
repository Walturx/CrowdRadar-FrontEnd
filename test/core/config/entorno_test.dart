import 'dart:io';

import 'package:crowdradar/core/config/entorno.dart';
import 'package:flutter_test/flutter_test.dart';

/// Finds pubspec.yaml walking up from the working directory, so the test does
/// not depend on where `flutter test` was launched from.
File _pubspec() {
  var dir = Directory.current;
  while (true) {
    final archivo = File('${dir.path}${Platform.pathSeparator}pubspec.yaml');
    if (archivo.existsSync()) return archivo;
    final padre = dir.parent;
    if (padre.path == dir.path) {
      throw StateError('pubspec.yaml not found above ${Directory.current}');
    }
    dir = padre;
  }
}

void main() {
  test('the shown app version matches pubspec.yaml', () {
    final pubspec = _pubspec().readAsStringSync();
    final version = RegExp(
      r'^version:\s*([^+\s]+)',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1);

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
