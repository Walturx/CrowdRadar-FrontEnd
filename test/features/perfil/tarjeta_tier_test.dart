import 'package:crowdradar/core/models/tier_usuario.dart';
import 'package:crowdradar/features/perfil/widgets/tarjeta_tier.dart';
import 'package:crowdradar/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> abrir(WidgetTester tester, {int puntos = 20}) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TarjetaTier(TierUsuario.crowdExplorer, puntos: puntos),
          ),
        ),
      );

  Finder enTarjeta(String texto) => find.descendant(
    of: find.byKey(TarjetaTier.clave),
    matching: find.text(texto),
  );

  testWidgets('D5 shows the points number with «puntos» below', (tester) async {
    await abrir(tester, puntos: 1280);

    expect(enTarjeta('1280'), findsOneWidget);
    expect(enTarjeta('puntos'), findsOneWidget);
    expect(
      tester.getTopLeft(enTarjeta('puntos')).dy,
      greaterThan(tester.getTopLeft(enTarjeta('1280')).dy),
    );
    // The points sit on the right of the tier name.
    expect(
      tester.getTopLeft(enTarjeta('1280')).dx,
      greaterThan(tester.getTopLeft(enTarjeta('Crowd Explorer')).dx),
    );
  });

  testWidgets('shows the «TU TIER» eyebrow and the tier name in white', (
    tester,
  ) async {
    await abrir(tester);

    expect(enTarjeta('TU TIER'), findsOneWidget);
    expect(
      tester.widget<Text>(enTarjeta('Crowd Explorer')).style?.color,
      Colors.white,
    );
  });

  testWidgets('is a brand blue card with radius 28', (tester) async {
    await abrir(tester);

    final caja = tester.widget<Container>(
      find.byKey(const ValueKey('perfil-tier-fondo')),
    );
    final deco = caja.decoration as BoxDecoration;
    expect(deco.color, AppColors.primary);
    expect(deco.borderRadius, BorderRadius.circular(28));
  });
}
