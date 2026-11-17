import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Applies only to the tests under `test/goldens/`.
///
/// Loads the Roboto and MaterialIcons fonts that ship with the Flutter SDK so
/// the golden images show real text and icons instead of Ahem boxes. The SDK
/// is found at runtime (see [_flutterRoot]); nothing is hard-coded to one
/// machine. When the fonts cannot be found, the goldens keep Ahem and a
/// warning is printed.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadSdkFonts();
  await testMain();
}

/// Roboto weights and styles the Material text theme can ask for.
const List<String> _robotoFiles = [
  'roboto-thin.ttf',
  'roboto-thinitalic.ttf',
  'roboto-light.ttf',
  'roboto-lightitalic.ttf',
  'roboto-regular.ttf',
  'roboto-italic.ttf',
  'roboto-medium.ttf',
  'roboto-mediumitalic.ttf',
  'roboto-bold.ttf',
  'roboto-bolditalic.ttf',
  'roboto-black.ttf',
  'roboto-blackitalic.ttf',
];

Future<void> _loadSdkFonts() async {
  final fontsDir = _materialFontsDir();
  if (fontsDir == null) {
    // ignore: avoid_print
    print(
      'goldens: Flutter SDK material_fonts not found; text renders as Ahem.',
    );
    return;
  }

  // Text whose style names no family still uses the engine's box font; the
  // harness fills those theme styles (see `golden_harness.dart`).
  final roboto = FontLoader('Roboto');
  for (final name in _robotoFiles) {
    final file = File('${fontsDir.path}${Platform.pathSeparator}$name');
    if (file.existsSync()) roboto.addFont(_bytesOf(file));
  }
  await roboto.load();

  final icons = FontLoader('MaterialIcons')
    ..addFont(
      _bytesOf(
        File(
          '${fontsDir.path}${Platform.pathSeparator}materialicons-regular.otf',
        ),
      ),
    );
  await icons.load();
}

Future<ByteData> _bytesOf(File file) async =>
    ByteData.sublistView(await file.readAsBytes());

/// `<flutter root>/bin/cache/artifacts/material_fonts`, or null.
Directory? _materialFontsDir() {
  final root = _flutterRoot();
  if (root == null) return null;
  final sep = Platform.pathSeparator;
  final dir = Directory(
    '${root.path}${sep}bin${sep}cache${sep}artifacts${sep}material_fonts',
  );
  return dir.existsSync() ? dir : null;
}

/// The Flutter SDK root: `FLUTTER_ROOT` when the tool exports it, otherwise
/// the ancestor of the test runner executable (`flutter_tester`, which lives
/// under `<root>/bin/cache/artifacts/engine/...`).
Directory? _flutterRoot() {
  final fromEnv = Platform.environment['FLUTTER_ROOT'];
  if (fromEnv != null && Directory(fromEnv).existsSync()) {
    return Directory(fromEnv);
  }
  Directory dir = File(Platform.resolvedExecutable).parent;
  while (true) {
    final sep = Platform.pathSeparator;
    if (Directory(
      '${dir.path}${sep}bin${sep}cache${sep}artifacts${sep}material_fonts',
    ).existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) return null;
    dir = parent;
  }
}
