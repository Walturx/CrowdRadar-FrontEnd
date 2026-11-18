import 'package:crowdradar/features/analitica/data/analitica_repository.dart';
import 'package:crowdradar/features/analitica/historial/historial_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/analitica_repository_fake.dart';
import '../fakes/enrutador_falso.dart';
import 'golden_harness.dart';

void main() {
  testWidgets('history, today by hour', (tester) async {
    usePhoneSurface(tester);
    // Place 1 is known to the fake: its hourly series is seeded by the id,
    // so it does not depend on the current date.
    await tester.pumpWidget(
      RepositoryProvider<AnaliticaRepository>.value(
        value: AnaliticaRepositoryFake(),
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: appTheme,
          builder: withoutAnimations,
          routerConfig: enrutadorDe(
            ruta: '/historial',
            inicial: '/historial',
            pantalla: const HistorialPage(lugarId: 1),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SATURACIÓN POR HORA · HOY'), findsOneWidget);
    await matchBaseline('historial_hoy');
  });
}
