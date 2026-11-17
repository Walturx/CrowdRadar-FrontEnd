import 'package:crowdradar/core/widgets/mostrar_aviso.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> abrir(
    WidgetTester tester,
    void Function(BuildContext) alPulsar,
  ) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => alPulsar(context),
              child: const Text('avisar'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows the text', (tester) async {
    await abrir(tester, (c) => mostrarAviso(c, 'Hola'));

    await tester.tap(find.text('avisar'));
    await tester.pump();

    expect(find.text('Hola'), findsOneWidget);
  });

  testWidgets('alLado sits beside the text in the snack bar', (tester) async {
    await abrir(
      tester,
      (c) => mostrarAviso(c, 'Hola', alLado: const Text('al lado')),
    );

    await tester.tap(find.text('avisar'));
    await tester.pump();

    final aviso = find.byKey(const ValueKey('mostrar-aviso'));
    final texto = find.descendant(of: aviso, matching: find.text('Hola'));
    final alLado = find.descendant(of: aviso, matching: find.text('al lado'));
    expect(texto, findsOneWidget);
    expect(alLado, findsOneWidget);
    // Beside: to the right of the text, on the same line.
    expect(
      tester.getRect(alLado).left,
      greaterThanOrEqualTo(tester.getRect(texto).right),
    );
    expect(tester.getCenter(alLado).dy, closeTo(tester.getCenter(texto).dy, 1));
  });

  testWidgets('a new notice replaces the current one', (tester) async {
    await abrir(tester, (c) => mostrarAviso(c, 'Uno'));
    await tester.tap(find.text('avisar'));
    await tester.pump();
    await abrir(tester, (c) => mostrarAviso(c, 'Dos'));
    await tester.tap(find.text('avisar'));
    await tester.pumpAndSettle();

    expect(find.text('Uno'), findsNothing);
    expect(find.text('Dos'), findsOneWidget);
  });

  testWidgets('an action runs its callback', (tester) async {
    var pulsado = false;
    await abrir(
      tester,
      (c) => mostrarAviso(
        c,
        'Hecho',
        etiquetaAccion: 'Deshacer',
        alAccionar: () => pulsado = true,
      ),
    );

    await tester.tap(find.text('avisar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deshacer'));

    expect(pulsado, isTrue);
  });
}
