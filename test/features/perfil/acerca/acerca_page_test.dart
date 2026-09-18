import 'package:crowdradar/core/config/entorno.dart';
import 'package:crowdradar/features/perfil/acerca/acerca_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('R8 shows the app name, version and OSM attribution', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AcercaPage()));

    expect(find.text('CrowdRadar'), findsWidgets);
    expect(find.text('Versión ${Entorno.version}'), findsOneWidget);
    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
    expect(find.textContaining('ODbL'), findsOneWidget);
    expect(find.text(AcercaPage.enlaceLicencia), findsOneWidget);
  });

  testWidgets('shows the team and course line', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AcercaPage()));

    expect(find.text(AcercaPage.lineaEquipo), findsOneWidget);
  });
}
