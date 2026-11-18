import 'package:crowdradar/layout/cr_bottom_nav.dart';
import 'package:crowdradar/theme/app_colors.dart';
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

  group('redesign (CRO-88 T8-G4)', () {
    Text etiqueta(WidgetTester tester, String texto) =>
        tester.widget<Text>(find.text(texto));

    testWidgets('the active item has a 60x30 primaryContainer pill', (
      tester,
    ) async {
      await abrir(tester);

      final pildora = find.byKey(const ValueKey('nav-indicador-activo'));
      expect(pildora, findsOneWidget);
      expect(tester.getSize(pildora), const Size(60, 30));
      final caja =
          tester.widget<Container>(pildora).decoration as BoxDecoration;
      expect(caja.color, AppColors.primaryContainer);
      // The pill sits on the active tab (Mapa, index 0).
      expect(
        tester.getCenter(pildora).dx,
        moreOrLessEquals(tester.getCenter(find.text('Mapa')).dx, epsilon: 1),
      );
    });

    testWidgets('the active item is primary and bold, the rest textMuted', (
      tester,
    ) async {
      await abrir(tester);

      expect(etiqueta(tester, 'Mapa').style?.color, AppColors.primary);
      expect(etiqueta(tester, 'Mapa').style?.fontWeight, FontWeight.w700);
      for (final t in ['Validar', 'Favoritos', 'Perfil']) {
        expect(etiqueta(tester, t).style?.color, AppColors.textMuted);
      }
    });

    testWidgets('the bar is white with a top border line', (tester) async {
      await abrir(tester);

      final barra = tester.widget<Container>(
        find.byKey(const ValueKey('nav-principal')),
      );
      final caja = barra.decoration as BoxDecoration;
      expect(caja.color, AppColors.surface);
      expect((caja.border as Border).top.color, AppColors.border);
    });

    testWidgets('the badge still shows with the pill', (tester) async {
      await abrir(tester, noLeidas: 5);

      expect(insigniaEnFavoritos('5'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('nav-indicador-activo')),
        findsOneWidget,
      );
    });

    testWidgets('every tab is at least 44x44', (tester) async {
      await abrir(tester);

      for (final t in ['Mapa', 'Validar', 'Favoritos', 'Perfil']) {
        final tam = tester.getSize(
          find.ancestor(of: find.text(t), matching: find.byType(InkWell)),
        );
        expect(tam.height, greaterThanOrEqualTo(44));
        expect(tam.width, greaterThanOrEqualTo(44));
      }
    });
  });

  testWidgets('only the Favoritos tab carries a badge', (tester) async {
    await abrir(tester, noLeidas: 2);

    expect(find.byKey(const Key('insignia-favoritos')), findsOneWidget);
    // The count shows once: no other tab repeats it.
    expect(find.text('2'), findsOneWidget);
  });
}
