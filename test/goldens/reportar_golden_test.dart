import 'package:crowdradar/features/reportes/data/reporte_repository.dart';
import 'package:crowdradar/features/reportes/reportar/reportar_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/reporte_repository_fake.dart';
import 'golden_harness.dart';

void main() {
  /// Opens the report sheet over a plain screen, as the detail page does.
  Future<void> open(WidgetTester tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(
      RepositoryProvider<ReporteRepository>.value(
        value: ReporteRepositoryFake(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: appTheme,
          builder: withoutAnimations,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => mostrarReportarSheet(
                    context,
                    lugarId: 1,
                    lugarNombre: 'Parque Kennedy',
                  ),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('report sheet, no level selected', (tester) async {
    await open(tester);

    expect(find.text('¿Qué tan lleno está?'), findsOneWidget);
    await matchBaseline('reportar_sin_seleccion');
  });

  testWidgets('report sheet, a level selected', (tester) async {
    await open(tester);

    await tester.tap(find.text('Moderado'));
    await tester.pumpAndSettle();

    await matchBaseline('reportar_seleccionado');
  });
}
