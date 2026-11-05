import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opens the district dropdown ([campo], or the only one on screen) and picks [distrito],
/// scrolling the menu until the option is built.
Future<void> elegirDistrito(
  WidgetTester tester,
  String distrito, {
  Finder? campo,
}) async {
  final desplegable = campo ?? find.byType(DropdownButtonFormField<String>);
  await tester.ensureVisible(desplegable);
  await tester.tap(desplegable);
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text(distrito),
    120,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(find.text(distrito).last);
  await tester.pumpAndSettle();
}
