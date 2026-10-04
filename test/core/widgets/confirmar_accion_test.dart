import 'package:crowdradar/core/widgets/confirmar_accion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  bool? resultado;

  Future<void> abrir(WidgetTester tester, {String? contenido}) async {
    resultado = null;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => resultado = await confirmarAccion(
              context,
              titulo: '¿Seguro?',
              contenido: contenido,
              etiquetaConfirmar: 'Borrar',
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('confirming returns true', (tester) async {
    await abrir(tester, contenido: 'Se pierde todo');

    expect(find.text('¿Seguro?'), findsOneWidget);
    expect(find.text('Se pierde todo'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Borrar'));
    await tester.pumpAndSettle();

    expect(resultado, isTrue);
  });

  testWidgets('cancelling returns false and the content is optional', (
    tester,
  ) async {
    await abrir(tester);

    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();

    expect(resultado, isFalse);
  });

  testWidgets('dismissing by tapping outside returns false, never null', (
    tester,
  ) async {
    await abrir(tester);

    await tester.tapAt(const Offset(2, 2));
    await tester.pumpAndSettle();

    expect(resultado, isFalse);
  });
}
