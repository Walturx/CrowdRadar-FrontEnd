import 'package:crowdradar/core/models/validacion.dart';
import 'package:crowdradar/features/validacion/widgets/chip_estado_validacion.dart';
import 'package:crowdradar/features/validacion/widgets/insignia_confiabilidad.dart';
import 'package:crowdradar/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Green, amber and red belong to saturation levels only (decision D6).
final _coloresDeNivel = <Color>{
  AppColors.tranquilo,
  AppColors.tranquiloBg,
  AppColors.tranquiloDot,
  AppColors.moderado,
  AppColors.moderadoBg,
  AppColors.moderadoDot,
  AppColors.saturado,
  AppColors.saturadoBg,
  AppColors.saturadoDot,
};

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

/// Every color painted by text, icons and boxes under [raiz].
Set<Color> _coloresPintados(WidgetTester tester, Finder raiz) {
  final colores = <Color>{};
  for (final w in tester.widgetList(
    find.descendant(of: raiz, matching: find.byWidgetPredicate((_) => true)),
  )) {
    switch (w) {
      case Text(:final style?) when style.color != null:
        colores.add(style.color!);
      case Icon(:final color?):
        colores.add(color);
      case Container(:final BoxDecoration decoration)
          when decoration.color != null:
        colores.add(decoration.color!);
    }
  }
  return colores;
}

void main() {
  group('ChipEstadoValidacion', () {
    for (final (estado, texto) in [
      (EstadoValidacion.validado, 'Validado'),
      (EstadoValidacion.enValidacion, 'En validación'),
      (EstadoValidacion.rechazado, 'Rechazado'),
      (EstadoValidacion.sinValidaciones, 'Sin validaciones'),
    ]) {
      testWidgets('$estado keeps "$texto" with an icon and neutral colors', (
        tester,
      ) async {
        await tester.pumpWidget(_app(ChipEstadoValidacion(estado: estado)));

        expect(find.text(texto), findsOneWidget);
        final icono = find.byKey(const ValueKey('icono-estado-validacion'));
        expect(icono, findsOneWidget);
        expect(
          tester.widget<Icon>(icono).icon,
          ChipEstadoValidacion.iconoDe(estado),
        );
        final colores = _coloresPintados(
          tester,
          find.byType(ChipEstadoValidacion),
        );
        expect(colores, isNotEmpty);
        expect(colores.intersection(_coloresDeNivel), isEmpty);
        expect(colores, isNot(contains(AppColors.danger)));
      });
    }

    test('each estado has its own icon', () {
      expect(
        EstadoValidacion.values.map(ChipEstadoValidacion.iconoDe).toSet(),
        hasLength(EstadoValidacion.values.length),
      );
    });
  });

  group('InsigniaConfiabilidad', () {
    for (final (nivel, porcentaje, texto) in [
      (NivelConfiabilidad.alta, 86.0, 'Confiabilidad Alta'),
      (NivelConfiabilidad.media, 55.0, 'Confiabilidad Media'),
      (NivelConfiabilidad.baja, 20.0, 'Confiabilidad Baja'),
      (
        NivelConfiabilidad.insuficiente,
        null,
        'Aún no hay suficientes validaciones',
      ),
    ]) {
      testWidgets('$nivel keeps its text with an icon and neutral colors', (
        tester,
      ) async {
        await tester.pumpWidget(
          _app(
            InsigniaConfiabilidad(
              confiabilidad: Confiabilidad(
                porcentaje: porcentaje,
                nivel: nivel,
              ),
            ),
          ),
        );

        expect(find.text(texto), findsOneWidget);
        if (porcentaje != null) {
          expect(find.text('${porcentaje.round()}%'), findsOneWidget);
        }
        final icono = find.byKey(const ValueKey('icono-confiabilidad'));
        expect(icono, findsOneWidget);
        expect(
          tester.widget<Icon>(icono).icon,
          InsigniaConfiabilidad.iconoDe(nivel),
        );
        final colores = _coloresPintados(
          tester,
          find.byType(InsigniaConfiabilidad),
        );
        expect(colores, isNotEmpty);
        expect(colores.intersection(_coloresDeNivel), isEmpty);
        expect(colores, isNot(contains(AppColors.danger)));
      });
    }

    test('each nivel has its own icon', () {
      expect(
        NivelConfiabilidad.values.map(InsigniaConfiabilidad.iconoDe).toSet(),
        hasLength(NivelConfiabilidad.values.length),
      );
    });
  });
}
