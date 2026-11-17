import 'package:crowdradar/layout/cr_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> abrir(WidgetTester tester, {int noLeidas = 0}) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: CrBottomNav(
              currentIndex: 0,
              onTap: (_) {},
              alertasNoLeidas: noLeidas,
            ),
          ),
        ),
      );

  Finder insigniaEnFavoritos(String cuenta) => find.descendant(
    of: find.byKey(const Key('insignia-favoritos')),
    matching: find.text(cuenta),
  );

  testWidgets('shows the unread count on the Favoritos tab', (tester) async {
    await abrir(tester, noLeidas: 3);

    expect(find.byKey(const Key('insignia-favoritos')), findsOneWidget);
    expect(insigniaEnFavoritos('3'), findsOneWidget);
  });

  testWidgets('hides the badge at zero', (tester) async {
    await abrir(tester);

    expect(find.byKey(const Key('insignia-favoritos')), findsNothing);
    expect(find.text('Favoritos'), findsOneWidget);
  });

  testWidgets('caps big counts at 99+', (tester) async {
    await abrir(tester, noLeidas: 120);

    expect(insigniaEnFavoritos('99+'), findsOneWidget);
  });

  testWidgets('only the Favoritos tab carries a badge', (tester) async {
    await abrir(tester, noLeidas: 2);

    expect(find.byKey(const Key('insignia-favoritos')), findsOneWidget);
    // The count shows once: no other tab repeats it.
    expect(find.text('2'), findsOneWidget);
  });
}
