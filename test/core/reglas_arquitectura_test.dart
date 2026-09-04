import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Iterable<File> _fuentes() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));

String _ruta(File f) => f.path.replaceAll('\\', '/');

/// Source files outside [carpeta] whose text matches [patron].
List<String> _infractores(RegExp patron, {required String fueraDe}) => _fuentes()
    .where((f) => !_ruta(f).startsWith(fueraDe))
    .where((f) => patron.hasMatch(f.readAsStringSync()))
    .map(_ruta)
    .toList();

void main() {
  test(
    'only lib/core/map may import flutter_map or latlong2 (AC4)',
    () {
      final infractores = _infractores(
        RegExp(r'''import\s+['"]package:(flutter_map|latlong2)/'''),
        fueraDe: 'lib/core/map/',
      );

      expect(
        infractores,
        isEmpty,
        reason: 'No import of package:flutter_map or package:latlong2 anywhere '
            'under lib/ except lib/core/map/ (Adapter boundary).',
      );
    },
  );

  test(
    'only lib/core/network may import package:http (AC5)',
    () {
      final infractores = _infractores(
        RegExp(r'''import\s+['"]package:http/'''),
        fueraDe: 'lib/core/network/',
      );

      expect(
        infractores,
        isEmpty,
        reason: "No import 'package:http/...' anywhere under lib/ except "
            'lib/core/network/ (features and app talk through ApiClient).',
      );
    },
  );
}
