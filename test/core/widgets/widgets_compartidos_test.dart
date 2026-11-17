import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/widgets/boton_principal.dart';
import 'package:crowdradar/core/widgets/cargando.dart';
import 'package:crowdradar/core/widgets/chip_saturacion.dart';
import 'package:crowdradar/core/widgets/estado_error.dart';
import 'package:crowdradar/core/widgets/medidor_nivel.dart';
import 'package:crowdradar/core/widgets/pin_saturacion.dart';
import 'package:crowdradar/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('EstadoError', () {
    testWidgets('shows the message and retries on tap', (tester) async {
      var reintentos = 0;
      await tester.pumpWidget(
        _app(EstadoError(mensaje: 'Falló', onReintentar: () => reintentos++)),
      );

      expect(find.text('Falló'), findsOneWidget);
      await tester.tap(find.text('Reintentar'));
      expect(reintentos, 1);
    });

    testWidgets('hides the retry button without a callback', (tester) async {
      await tester.pumpWidget(_app(const EstadoError(mensaje: 'Sin red')));

      expect(find.text('Sin red'), findsOneWidget);
      expect(find.text('Reintentar'), findsNothing);
    });
  });

  testWidgets('Cargando shows a progress indicator', (tester) async {
    await tester.pumpWidget(_app(const Cargando()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  group('ChipSaturacion', () {
    for (final (nivel, texto) in [
      (NivelSaturacion.tranquilo, 'Tranquilo'),
      (NivelSaturacion.moderado, 'Moderado'),
      (NivelSaturacion.saturado, 'Saturado'),
      (NivelSaturacion.sinInformacion, 'Sin información'),
    ]) {
      testWidgets('labels $nivel as "$texto"', (tester) async {
        await tester.pumpWidget(_app(ChipSaturacion(nivel: nivel)));

        expect(find.text(texto), findsOneWidget);
      });
    }

    for (final (nivel, fg, bg) in [
      (NivelSaturacion.tranquilo, AppColors.tranquilo, AppColors.tranquiloBg),
      (NivelSaturacion.moderado, AppColors.moderado, AppColors.moderadoBg),
      (NivelSaturacion.saturado, AppColors.saturado, AppColors.saturadoBg),
      (
        NivelSaturacion.sinInformacion,
        AppColors.sinDatos,
        AppColors.sinDatosBg,
      ),
    ]) {
      testWidgets('$nivel is a 28 px pill with a meter and fg text on bg', (
        tester,
      ) async {
        await tester.pumpWidget(
          _app(Center(child: ChipSaturacion(nivel: nivel))),
        );

        final pastilla = find.byKey(const ValueKey('chip-saturacion'));
        expect(tester.getSize(pastilla).height, 28);
        final fondo = tester.widget<Container>(pastilla).decoration!;
        expect((fondo as BoxDecoration).color, bg);
        expect(ChipSaturacion.bgDe(nivel), bg);
        expect(ChipSaturacion.fgDe(nivel), fg);

        final medidor = find.descendant(
          of: pastilla,
          matching: find.byKey(const ValueKey('medidor-nivel')),
        );
        expect(medidor, findsOneWidget);
        expect(tester.widget<MedidorNivel>(medidor).color, fg);
        expect(tester.widget<MedidorNivel>(medidor).nivel, nivel);

        final texto = tester.widget<Text>(
          find.descendant(
            of: pastilla,
            matching: find.text(ChipSaturacion.etiquetaDe(nivel)),
          ),
        );
        expect(texto.style!.color, fg);
      });
    }

    test('describes each level as in the design system', () {
      expect(NivelSaturacion.values.map(ChipSaturacion.descripcionDe), [
        'Hay espacio, poca gente',
        'Algo concurrido',
        'Lleno, mucha gente',
        'Sin reportes recientes',
      ]);
    });

    test('colorDe is the dot color used by pins and charts', () {
      expect(
        ChipSaturacion.colorDe(NivelSaturacion.tranquilo),
        AppColors.tranquiloDot,
      );
      expect(
        ChipSaturacion.colorDe(NivelSaturacion.moderado),
        AppColors.moderadoDot,
      );
      expect(
        ChipSaturacion.colorDe(NivelSaturacion.saturado),
        AppColors.saturadoDot,
      );
      expect(
        ChipSaturacion.colorDe(NivelSaturacion.sinInformacion),
        AppColors.sinDatosDot,
      );
    });

    test('each level has its own color', () {
      final colores = NivelSaturacion.values
          .map(ChipSaturacion.colorDe)
          .toSet();

      expect(colores, hasLength(NivelSaturacion.values.length));
    });
  });

  group('BotonPrincipal', () {
    testWidgets('fires onPressed', (tester) async {
      var toques = 0;
      await tester.pumpWidget(
        _app(BotonPrincipal(texto: 'Guardar', onPressed: () => toques++)),
      );

      await tester.tap(find.text('Guardar'));
      expect(toques, 1);
    });

    testWidgets('while loading it is disabled and shows a spinner', (
      tester,
    ) async {
      var toques = 0;
      await tester.pumpWidget(
        _app(
          BotonPrincipal(
            texto: 'Guardar',
            cargando: true,
            onPressed: () => toques++,
          ),
        ),
      );

      await tester.tap(find.byType(BotonPrincipal));
      expect(toques, 0);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Guardar'), findsNothing);
    });
  });

  testWidgets('PinSaturacion taps through and uses the level color', (
    tester,
  ) async {
    var toques = 0;
    await tester.pumpWidget(
      _app(
        PinSaturacion(nivel: NivelSaturacion.saturado, onTap: () => toques++),
      ),
    );

    await tester.tap(find.byType(PinSaturacion));
    expect(toques, 1);
    final gota = tester.widget<Container>(
      find.byKey(const ValueKey('pin-saturacion-icono')),
    );
    final decoracion = gota.decoration! as BoxDecoration;
    expect(decoracion.color, AppColors.saturadoDot);
    expect(decoracion.border, Border.all(color: Colors.white, width: 2.5));
    final medidor = tester.widget<MedidorNivel>(
      find.descendant(
        of: find.byType(PinSaturacion),
        matching: find.byKey(const ValueKey('medidor-nivel')),
      ),
    );
    expect(medidor.color, Colors.white);
    expect(medidor.nivel, NivelSaturacion.saturado);
  });

  testWidgets('PinSaturacion is a 34 px drop inside a 44 px touch target', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const Center(child: PinSaturacion(nivel: NivelSaturacion.tranquilo)),
      ),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey('pin-saturacion-icono'))),
      const Size(34, 34),
    );
    final caja = tester.getSize(find.byType(PinSaturacion));
    expect(caja.width, greaterThanOrEqualTo(44));
    expect(caja.height, greaterThanOrEqualTo(44));
  });
}
