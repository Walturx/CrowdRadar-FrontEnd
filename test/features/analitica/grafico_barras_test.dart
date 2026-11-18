import 'package:crowdradar/core/models/analitica.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/widgets/chip_saturacion.dart';
import 'package:crowdradar/features/analitica/widgets/grafico_barras.dart';
import 'package:crowdradar/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The 24 hourly slots the backend sends (CRO-64): only [llenas] have reports,
/// the rest come with valor 0 and muestras 0.
List<PuntoSerie> _franjas(Map<int, PuntoSerie> llenas) => [
  for (var h = 0; h < 24; h++) llenas[h] ?? PuntoSerie(etiquetaHora(h), 0),
];

void main() {
  Future<void> dibujar(WidgetTester tester, GraficoBarras grafico) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SizedBox(width: 480, child: grafico)),
      ),
    );
  }

  List<Rect> barras(WidgetTester tester) => [
    for (final e in find.byKey(const Key('barra-saturacion')).evaluate())
      tester.getRect(find.byWidget(e.widget)),
  ];

  testWidgets(
    'a place with reports only at 15:00 shows one bar at 15h and an empty axis '
    'elsewhere (CRO-64)',
    (tester) async {
      await dibujar(
        tester,
        GraficoBarras(
          puntos: _franjas({15: const PuntoSerie('15:00', 2, muestras: 5)}),
          eje: GraficoBarras.ejeHoras,
        ),
      );

      final rects = barras(tester);
      expect(rects, hasLength(24));
      final conReportes = [
        for (var i = 0; i < rects.length; i++)
          if (rects[i].height > GraficoBarras.altoSinReportes) i,
      ];
      expect(conReportes, [15]);
      final ancho = tester.getSize(find.byType(GraficoBarras)).width;
      expect(
        rects[15].center.dx,
        inInclusiveRange(ancho * 15 / 24, ancho * 16 / 24),
      );
    },
  );

  /// The decoration of every bar, left to right.
  List<BoxDecoration> decoraciones(WidgetTester tester) => [
    for (final c in tester.widgetList<Container>(
      find.byKey(const Key('barra-saturacion')),
    ))
      c.decoration! as BoxDecoration,
  ];

  testWidgets('CRO-88 an hour without reports is a 6 px stub in the border '
      'color', (tester) async {
    await dibujar(
      tester,
      GraficoBarras(
        puntos: _franjas({15: const PuntoSerie('15:00', 2, muestras: 5)}),
      ),
    );

    final rects = barras(tester);
    final deco = decoraciones(tester);
    for (var i = 0; i < 24; i++) {
      if (i == 15) continue;
      expect(rects[i].height, 6, reason: 'slot $i');
      expect(deco[i].color, AppColors.border, reason: 'slot $i');
    }
  });

  testWidgets('CRO-88 an hour with reports uses the level dot color and a '
      'rounded top', (tester) async {
    await dibujar(
      tester,
      GraficoBarras(
        puntos: _franjas({
          9: const PuntoSerie('09:00', 1, muestras: 3),
          12: const PuntoSerie('12:00', 2, muestras: 5),
          15: const PuntoSerie('15:00', 3, muestras: 8),
        }),
      ),
    );

    final deco = decoraciones(tester);
    expect(deco[9].color, ChipSaturacion.colorDe(NivelSaturacion.tranquilo));
    expect(deco[12].color, ChipSaturacion.colorDe(NivelSaturacion.moderado));
    expect(deco[15].color, ChipSaturacion.colorDe(NivelSaturacion.saturado));
    expect(
      deco[15].borderRadius,
      const BorderRadius.vertical(top: Radius.circular(4)),
    );
  });

  testWidgets('CRO-88 the legend uses 10 px squares beside each level name', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: LeyendaBarras())),
    );

    for (final nivel in [
      NivelSaturacion.tranquilo,
      NivelSaturacion.moderado,
      NivelSaturacion.saturado,
    ]) {
      final cuadro = find.byKey(ValueKey('leyenda-cuadro-${nivel.name}'));
      expect(tester.getSize(cuadro), const Size(10, 10));
      expect(
        (tester.widget<Container>(cuadro).decoration! as BoxDecoration).color,
        ChipSaturacion.colorDe(nivel),
      );
      expect(find.text(ChipSaturacion.etiquetaDe(nivel)), findsOneWidget);
    }
  });

  testWidgets('an empty slot says it has no reports instead of a 0.0 level', (
    tester,
  ) async {
    await dibujar(
      tester,
      GraficoBarras(
        puntos: _franjas({15: const PuntoSerie('15:00', 2, muestras: 5)}),
      ),
    );

    expect(find.byTooltip('03:00: sin reportes'), findsOneWidget);
    expect(find.byTooltip('03:00: 0.0'), findsNothing);
    expect(find.byTooltip('15:00: 2.0'), findsOneWidget);
  });

  /// Long-presses the middle of the [indice]-th of [total] slots, at
  /// [alturaRelativa] of the bars area height (0 = bottom, 1 = top).
  Future<void> mantenerFranja(
    WidgetTester tester,
    int indice,
    int total, {
    double alturaRelativa = 0.5,
  }) async {
    final grafico = tester.getRect(find.byType(GraficoBarras));
    await tester.longPressAt(
      Offset(
        grafico.left + grafico.width * (indice + 0.5) / total,
        grafico.top + 120 * (1 - alturaRelativa),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> esperarQueSeOculte(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  testWidgets('pressing an empty slot shows that it has no reports', (
    tester,
  ) async {
    await dibujar(
      tester,
      GraficoBarras(
        puntos: _franjas({15: const PuntoSerie('15:00', 2, muestras: 5)}),
      ),
    );

    await mantenerFranja(tester, 3, 24);

    expect(find.text('03:00: sin reportes'), findsOneWidget);
    await esperarQueSeOculte(tester);
  });

  testWidgets('pressing a bar still shows its value', (tester) async {
    await dibujar(
      tester,
      GraficoBarras(
        puntos: _franjas({15: const PuntoSerie('15:00', 2, muestras: 5)}),
      ),
    );

    await mantenerFranja(tester, 15, 24, alturaRelativa: 0.2);

    expect(find.text('15:00: 2.0'), findsOneWidget);
    await esperarQueSeOculte(tester);
  });

  testWidgets(
    'a 7 day range with a day without reports keeps that day, empty (CRO-64)',
    (tester) async {
      await dibujar(
        tester,
        const GraficoBarras(
          puntos: [
            PuntoSerie('2026-10-01', 1.5, muestras: 6),
            PuntoSerie('2026-10-02', 2, muestras: 8),
            PuntoSerie('2026-10-03', 1.2, muestras: 5),
            PuntoSerie('2026-10-04', 2.4, muestras: 9),
            PuntoSerie('2026-10-05', 1.8, muestras: 7),
            PuntoSerie('2026-10-06', 0),
            PuntoSerie('2026-10-07', 2.1, muestras: 6),
          ],
        ),
      );

      final rects = barras(tester);
      expect(rects, hasLength(7));
      expect(rects[5].height, GraficoBarras.altoSinReportes);
      expect(find.byTooltip('2026-10-06: sin reportes'), findsOneWidget);
      expect(find.text('2026-10-01'), findsOneWidget);
      expect(find.text('2026-10-07'), findsOneWidget);
    },
  );
}
