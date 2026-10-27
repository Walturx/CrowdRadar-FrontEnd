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

  Finder insigniaEnFavoritos() => find.descendant(
    of: find.byKey(const Key('insignia-favoritos')),
    matching: find.byType(Text),
  );

  testWidgets('shows the unread count on the Favoritos tab', (tester) async {
    await abrir(tester, noLeidas: 3);

    expect(find.byKey(const Key('insignia-favoritos')), findsOneWidget);
    expect(tester.widget<Text>(insigniaEnFavoritos()).data, '3');
  });

  testWidgets('hides the badge at zero', (tester) async {
    await abrir(tester);

    expect(find.byKey(const Key('insignia-favoritos')), findsNothing);
    expect(find.text('Favoritos'), findsOneWidget);
  });

  testWidgets('caps big counts at 99+', (tester) async {
    await abrir(tester, noLeidas: 120);

    expect(tester.widget<Text>(insigniaEnFavoritos()).data, '99+');
  });

  testWidgets('only the Favoritos tab carries a badge', (tester) async {
    await abrir(tester, noLeidas: 2);

    expect(find.byKey(const Key('insignia-favoritos')), findsOneWidget);
    expect(find.byType(Badge), findsOneWidget);
  });
}
