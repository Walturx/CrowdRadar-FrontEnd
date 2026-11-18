import 'package:crowdradar/core/models/moderacion.dart';
import 'package:crowdradar/features/moderacion/widgets/chip_estado_cuenta.dart';
import 'package:crowdradar/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('Activo is success text with a green dot (design-system §2.3)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const ChipEstadoCuenta(estado: EstadoCuenta.activo)),
    );

    final texto = tester.widget<Text>(find.text('Activo'));
    expect(texto.style!.color, AppColors.tranquilo);
    final punto = tester.widget<Container>(
      find.byKey(const ValueKey('punto-estado-cuenta')),
    );
    expect((punto.decoration! as BoxDecoration).color, AppColors.tranquiloDot);
    expect(find.byKey(const ValueKey('icono-estado-cuenta')), findsNothing);
  });

  testWidgets('Suspendido is danger on dangerBg with a block icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const ChipEstadoCuenta(estado: EstadoCuenta.suspendido)),
    );

    final texto = tester.widget<Text>(find.text('Suspendido'));
    expect(texto.style!.color, AppColors.danger);
    final fondo = tester.widget<Container>(
      find.byKey(const ValueKey('chip-estado-cuenta')),
    );
    expect((fondo.decoration! as BoxDecoration).color, AppColors.dangerBg);
    final icono = tester.widget<Icon>(
      find.byKey(const ValueKey('icono-estado-cuenta')),
    );
    expect(icono.icon, Icons.block);
    expect(icono.color, AppColors.danger);
    expect(find.byKey(const ValueKey('punto-estado-cuenta')), findsNothing);
  });
}
