import 'package:crowdradar/core/widgets/boton_con_espera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  var toques = 0;
  setUp(() => toques = 0);

  Widget app(int? segundos) => MaterialApp(
        home: Scaffold(
          body: BotonConEspera(
            texto: 'Enviar',
            segundos: segundos,
            onPressed: () => toques++,
          ),
        ),
      );

  Finder boton() => find.byType(ElevatedButton);
  bool habilitado(WidgetTester t) => t.widget<ElevatedButton>(boton()).enabled;

  testWidgets('without a wait it is a normal enabled button', (tester) async {
    await tester.pumpWidget(app(null));

    expect(find.text('Enviar'), findsOneWidget);
    expect(habilitado(tester), isTrue);
    await tester.tap(boton());
    expect(toques, 1);
  });

  testWidgets('with a wait it is disabled and counts down every second', (
    tester,
  ) async {
    await tester.pumpWidget(app(3));

    expect(find.text('Enviar (3s)'), findsOneWidget);
    expect(habilitado(tester), isFalse);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Enviar (2s)'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Enviar'), findsOneWidget);
    expect(habilitado(tester), isTrue);
  });

  testWidgets('a new wait restarts the countdown', (tester) async {
    await tester.pumpWidget(app(5));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Enviar (3s)'), findsOneWidget);

    await tester.pumpWidget(app(10));

    expect(find.text('Enviar (10s)'), findsOneWidget);
  });

  testWidgets('a zero wait never disables the button', (tester) async {
    await tester.pumpWidget(app(0));

    expect(habilitado(tester), isTrue);
  });

  testWidgets('disposing mid countdown leaves no pending timer', (
    tester,
  ) async {
    await tester.pumpWidget(app(30));
    await tester.pumpWidget(const SizedBox());

    // The binding fails the test if a periodic timer is still alive.
  });
}
