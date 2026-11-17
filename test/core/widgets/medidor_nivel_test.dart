import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/widgets/medidor_nivel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

/// Opacity of bar [i]: 1 when filled, 0.25 when empty.
double _alfaDeBarra(WidgetTester tester, int i) {
  final barra = tester.widget<Container>(
    find.byKey(ValueKey('medidor-barra-$i')),
  );
  return (barra.decoration! as BoxDecoration).color!.a;
}

void main() {
  const color = Color(0xFF15803D);

  for (final (nivel, llenas) in [
    (NivelSaturacion.tranquilo, 1),
    (NivelSaturacion.moderado, 2),
    (NivelSaturacion.saturado, 3),
    (NivelSaturacion.sinInformacion, 0),
  ]) {
    testWidgets('$nivel fills $llenas of 3 bars', (tester) async {
      await tester.pumpWidget(_app(MedidorNivel(nivel: nivel, color: color)));

      final alfas = [for (var i = 0; i < 3; i++) _alfaDeBarra(tester, i)];
      expect(find.byKey(const ValueKey('medidor-barra-3')), findsNothing);
      expect(alfas.where((a) => a == 1), hasLength(llenas));
      expect(
        alfas.where((a) => (a - 0.25).abs() < 0.01),
        hasLength(3 - llenas),
      );
      expect(MedidorNivel.barrasLlenasDe(nivel), llenas);
    });
  }

  testWidgets('bars are 4 px wide, 6/10/14 px high and 2 px apart', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const MedidorNivel(nivel: NivelSaturacion.saturado, color: color)),
    );

    final rects = [
      for (var i = 0; i < 3; i++)
        tester.getRect(find.byKey(ValueKey('medidor-barra-$i'))),
    ];
    expect(rects.map((r) => r.width), [4, 4, 4]);
    expect(rects.map((r) => r.height), [6, 10, 14]);
    expect(rects[1].left - rects[0].right, 2);
    expect(rects[2].left - rects[1].right, 2);
    // Bars share the baseline.
    expect(rects.map((r) => r.bottom).toSet(), hasLength(1));
    expect(
      tester.getSize(find.byKey(const ValueKey('medidor-nivel'))),
      const Size(16, 14),
    );
  });

  testWidgets('the scale factor grows the meter to 34 px high', (tester) async {
    await tester.pumpWidget(
      _app(
        const MedidorNivel(
          nivel: NivelSaturacion.moderado,
          color: color,
          escala: 34 / 14,
        ),
      ),
    );

    final alto = tester
        .getSize(find.byKey(const ValueKey('medidor-nivel')))
        .height;
    expect(alto, closeTo(34, 0.01));
  });

  testWidgets('filled bars paint the given color', (tester) async {
    await tester.pumpWidget(
      _app(const MedidorNivel(nivel: NivelSaturacion.tranquilo, color: color)),
    );

    final barra = tester.widget<Container>(
      find.byKey(const ValueKey('medidor-barra-0')),
    );
    expect((barra.decoration! as BoxDecoration).color, color);
  });
}
