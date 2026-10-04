import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Iterable<File> _fuentes() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));

String _ruta(File f) => f.path.replaceAll('\\', '/');

void main() {
  test('AC4 only core/map imports flutter_map or latlong2', () {
    final infractores = _fuentes()
        .where((f) => !_ruta(f).startsWith('lib/core/map/'))
        .where((f) {
          final texto = f.readAsStringSync();
          return texto.contains('package:flutter_map/') ||
              texto.contains('package:latlong2/');
        })
        .map(_ruta);

    expect(infractores, isEmpty);
  });

  test('AC5 no direct http calls outside core/network', () {
    final llamada = RegExp(r'\bhttp\.(post|get|put|patch|delete|head)\(');
    final infractores = _fuentes()
        .where((f) => !_ruta(f).startsWith('lib/core/network/'))
        .where((f) => llamada.hasMatch(f.readAsStringSync()))
        .map(_ruta);

    expect(infractores, isEmpty);
  });

  test('features never import package:http', () {
    final infractores = _fuentes()
        .where((f) => _ruta(f).startsWith('lib/features/'))
        .where((f) => f.readAsStringSync().contains('package:http/'))
        .map(_ruta);

    expect(infractores, isEmpty);
  });
}
