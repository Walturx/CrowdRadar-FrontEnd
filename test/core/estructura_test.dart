import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const nuevos = ['app', 'core', 'features', 'layout', 'theme'];
  const viejos = [
    'components',
    'configs',
    'cubits',
    'models',
    'pages',
    'router',
    'services',
  ];

  test('S1.1 lib contains only the new top-level dirs plus main.dart', () {
    final entradas = Directory('lib')
        .listSync()
        .map((e) => e.uri.pathSegments.where((s) => s.isNotEmpty).last)
        .toSet();
    expect(entradas, {...nuevos, 'main.dart'});
  });

  for (final dir in viejos) {
    test('S1.1 old dir lib/$dir is absent', () {
      expect(Directory('lib/$dir').existsSync(), isFalse);
    });
  }
}
