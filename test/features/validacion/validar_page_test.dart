import 'package:crowdradar/app/fakes/comportamiento_fake.dart';
import 'package:crowdradar/app/fakes/validacion_repository_fake.dart';
import 'package:crowdradar/core/map/centro_compartido.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/features/validacion/data/validacion_repository.dart';
import 'package:crowdradar/features/validacion/pendientes/validar_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> abrir(WidgetTester tester, ValidacionRepository repo) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      RepositoryProvider<ValidacionRepository>.value(
        value: repo,
        child: MaterialApp(home: ValidarPage(centro: CentroMapaCompartido())),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('shows the nearest pending report with its reliability', (
    tester,
  ) async {
    await abrir(tester, ValidacionRepositoryFake());

    expect(find.text('Validar reportes'), findsOneWidget);
    expect(find.text('Parque Kennedy'), findsOneWidget);
    expect(find.text('400 m'), findsOneWidget);
    expect(find.text('Saturado'), findsOneWidget);
    expect(find.textContaining('Confiabilidad Alta'), findsOneWidget);
    expect(find.text('Confirmar'), findsOneWidget);
    expect(find.text('Rechazar'), findsOneWidget);
  });

  testWidgets('confirming thanks the user with +2 karma and advances', (
    tester,
  ) async {
    await abrir(tester, ValidacionRepositoryFake());

    await tester.tap(find.text('Confirmar'));
    await tester.pump();
    await tester.pump();

    expect(find.text('¡Gracias por validar!'), findsOneWidget);
    expect(find.text('+2 karma'), findsOneWidget);
    expect(find.textContaining('Confirmaste'), findsOneWidget);
    expect(find.text('Mercado de Surquillo'), findsOneWidget);
    expect(find.text('Parque Kennedy'), findsNothing);
  });

  testWidgets('after the last report the empty state appears', (tester) async {
    await abrir(tester, ValidacionRepositoryFake());

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Rechazar'));
      await tester.pumpAndSettle();
    }

    expect(find.text('No hay reportes por validar'), findsOneWidget);
  });

  testWidgets('an offline load shows the error with a retry', (tester) async {
    await abrir(
      tester,
      ValidacionRepositoryFake(
        comportamiento: const ComportamientoFake(
          fallo: ApiException.sinConexion(),
        ),
      ),
    );

    expect(find.text('Reintentar'), findsOneWidget);
  });
}
