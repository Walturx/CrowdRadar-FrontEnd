import 'package:crowdradar/app/app.dart';
import 'package:crowdradar/app/arranque.dart';
import 'package:crowdradar/app/dependencias.dart';
import 'package:crowdradar/core/config/entorno.dart';
import 'package:crowdradar/core/session/session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/registro_falso.dart';

void main() {
  tearDown(() => SessionService.instance.reiniciar());

  testWidgets('R4-107 failing bootstrap shows an error screen and retries', (
    tester,
  ) async {
    final registro = RegistroFalso();
    var intentos = 0;
    await tester.pumpWidget(
      ArranqueApp(
        registro: registro,
        iniciar: () async {
          intentos++;
          if (intentos == 1) throw StateError('keystore');
          return Dependencias.crear(
            const Entorno(usarFakes: true),
            SessionService.instance..reiniciar(),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reintentar'), findsOneWidget);
    expect(registro.registros.single.contexto, 'arranque');

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.byType(CrowdRadarApp), findsOneWidget);
    expect(find.text('Reintentar'), findsNothing);
  });

  testWidgets('successful bootstrap goes straight to the app', (tester) async {
    await tester.pumpWidget(
      ArranqueApp(
        registro: RegistroFalso(),
        iniciar: () async => Dependencias.crear(
          const Entorno(usarFakes: true),
          SessionService.instance..reiniciar(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CrowdRadarApp), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(MaterialApp), findsWidgets);
  });
}
