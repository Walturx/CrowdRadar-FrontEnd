import 'package:crowdradar/core/models/moderacion.dart';
import 'package:crowdradar/features/moderacion/data/moderacion_repository.dart';
import 'package:crowdradar/features/moderacion/denunciados/denunciados_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/enrutador_falso.dart';
import '../fakes/moderacion_repository_fake.dart';
import 'golden_harness.dart';

void main() {
  Future<void> open(WidgetTester tester, ModeracionRepository repo) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(
      RepositoryProvider<ModeracionRepository>.value(
        value: repo,
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: appTheme,
          builder: withoutAnimations,
          routerConfig: enrutadorDe(
            ruta: '/admin/reportes',
            inicial: '/admin/reportes',
            pantalla: const DenunciadosPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('moderation, reported reports loaded', (tester) async {
    // The fake dates its reports whole hours before now ("hace 1 h", ...).
    await open(tester, ModeracionRepositoryFake());

    expect(find.text('Reportes denunciados'), findsOneWidget);
    await matchBaseline('moderacion_denunciados');
  });

  testWidgets('moderation, empty queue', (tester) async {
    final repo = ModeracionRepositoryFake();
    for (final r in (await repo.reportesDenunciados()).items) {
      await repo.resolver(r.reporteId, DecisionModeracion.mantener);
    }
    await open(tester, repo);

    await matchBaseline('moderacion_vacio');
  });
}
