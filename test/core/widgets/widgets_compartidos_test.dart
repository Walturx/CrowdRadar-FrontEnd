import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/widgets/boton_principal.dart';
import 'package:crowdradar/core/widgets/cargando.dart';
import 'package:crowdradar/core/widgets/chip_saturacion.dart';
import 'package:crowdradar/core/widgets/estado_error.dart';
import 'package:crowdradar/core/widgets/pin_saturacion.dart';
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

      await tester.tap(find.byType(ElevatedButton));
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
    final icono = tester.widget<Icon>(find.byIcon(Icons.location_on));
    expect(icono.color, ChipSaturacion.colorDe(NivelSaturacion.saturado));
  });
}
