import 'package:crowdradar/app/app.dart';
import 'package:crowdradar/app/dependencias.dart';
import 'package:crowdradar/core/config/entorno.dart';
import 'package:crowdradar/core/session/session_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke test: la app arranca en la pantalla de login', (
    WidgetTester tester,
  ) async {
    final sesion = SessionService.instance..reiniciar();
    await tester.pumpWidget(
      CrowdRadarApp(dependencias: Dependencias.crear(const Entorno(), sesion)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('boton-iniciar-sesion')), findsOneWidget);
  });
}
