import 'package:crowdradar/app/fakes/moderacion_repository_fake.dart';
import 'package:crowdradar/features/moderacion/data/moderacion_repository.dart';
import 'package:crowdradar/features/moderacion/usuario_detalle/usuario_admin_detalle_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const idCarlos = 11;
  const idLucia = 12;
  const idAdmin = 10;

  Future<void> abrir(WidgetTester tester, int id) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      RepositoryProvider<ModeracionRepository>.value(
        value: ModeracionRepositoryFake(),
        child: MaterialApp(home: UsuarioAdminDetallePage(usuarioId: id)),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  final dialogo = find.byType(AlertDialog);

  testWidgets('HU 7.2 c3 shows name, email, status and report counters', (
    tester,
  ) async {
    await abrir(tester, idCarlos);

    expect(find.text('Detalle de usuario'), findsOneWidget);
    expect(find.text('Cuenta activa'), findsOneWidget);
    expect(find.text('INFORMACIÓN DE LA CUENTA'), findsOneWidget);
    expect(find.text('Carlos Méndez'), findsWidgets);
    expect(find.text('carlos.mendez@correo.pe'), findsWidgets);
    expect(find.text('Activa'), findsOneWidget);
    expect(find.text('32'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('HU 7.3 c1 the suspend dialog offers 3, 7 and 30 days', (
    tester,
  ) async {
    await abrir(tester, idCarlos);

    await tester.tap(find.text('Suspender usuario'));
    await tester.pumpAndSettle();

    expect(find.text('Duración de la suspensión'), findsOneWidget);
    expect(find.text('3 días'), findsOneWidget);
    expect(find.text('7 días'), findsOneWidget);
    expect(find.text('30 días'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Confirmar'))
          .onPressed,
      isNull,
    );
  });

  testWidgets('Confirmar needs a duration and a motivo of 10+ characters', (
    tester,
  ) async {
    await abrir(tester, idCarlos);
    await tester.tap(find.text('Suspender usuario'));
    await tester.pumpAndSettle();
    VoidCallback? confirmar() => tester
        .widget<TextButton>(find.widgetWithText(TextButton, 'Confirmar'))
        .onPressed;

    await tester.tap(find.text('7 días'));
    await tester.pump();
    expect(confirmar(), isNull);

    await tester.enterText(
      find.descendant(of: dialogo, matching: find.byType(TextField)),
      'corto',
    );
    await tester.pump();
    expect(confirmar(), isNull);

    await tester.enterText(
      find.descendant(of: dialogo, matching: find.byType(TextField)),
      'Reportes fraudulentos reiterados',
    );
    await tester.pump();
    expect(confirmar(), isNotNull);
  });

  testWidgets('HU 7.3 c2 confirming suspends the account and says so', (
    tester,
  ) async {
    await abrir(tester, idCarlos);
    await tester.tap(find.text('Suspender usuario'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('7 días'));
    await tester.enterText(
      find.descendant(of: dialogo, matching: find.byType(TextField)),
      'Reportes fraudulentos reiterados',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Confirmar'));
    await tester.pumpAndSettle();

    expect(dialogo, findsNothing);
    expect(
      find.text(
        'Carlos Méndez no podrá publicar reportes durante 7 días. '
        'Se le notificó el motivo.',
      ),
      findsOneWidget,
    );
    expect(find.text('Cuenta suspendida'), findsOneWidget);
    expect(find.text('Reactivar cuenta'), findsOneWidget);
    expect(find.text('Suspender usuario'), findsNothing);
  });

  testWidgets('cancelling the dialog changes nothing', (tester) async {
    await abrir(tester, idCarlos);
    await tester.tap(find.text('Suspender usuario'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Cuenta activa'), findsOneWidget);
  });

  testWidgets('HU 7.4 a suspended user shows the days left and reactivates', (
    tester,
  ) async {
    await abrir(tester, idLucia);

    expect(find.text('Cuenta suspendida'), findsOneWidget);
    expect(find.text('Suspendida · faltan 5 días'), findsOneWidget);

    await tester.tap(find.text('Reactivar cuenta'));
    await tester.pumpAndSettle();
    expect(dialogo, findsOneWidget);
    await tester.tap(find.text('Reactivar'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Lucía Paredes recuperó el acceso y ya puede volver a publicar reportes.',
      ),
      findsOneWidget,
    );
    expect(find.text('Cuenta activa'), findsOneWidget);
  });

  testWidgets('an admin account has no suspend button', (tester) async {
    await abrir(tester, idAdmin);

    expect(find.text('Cuenta activa'), findsOneWidget);
    expect(find.text('Suspender usuario'), findsNothing);
  });

  testWidgets('an unknown user shows the error', (tester) async {
    await abrir(tester, 9999);

    expect(find.text('Usuario no encontrado'), findsOneWidget);
  });
}
