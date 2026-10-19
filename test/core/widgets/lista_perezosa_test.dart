import 'package:crowdradar/core/widgets/lista_perezosa.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<List<int>> montar(WidgetTester tester, {int filas = 3}) async {
    final construidas = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListaPerezosa(
            cabecera: const [Text('cabecera')],
            cantidad: filas,
            fila: (context, i) {
              construidas.add(i);
              return SizedBox(height: 100, child: Text('fila $i'));
            },
            pie: const [Text('pie')],
          ),
        ),
      ),
    );
    return construidas;
  }

  testWidgets('renders header, rows in order and footer', (tester) async {
    await montar(tester);

    expect(find.byType(ListView), findsOneWidget);
    final y = [
      'cabecera',
      'fila 0',
      'fila 1',
      'fila 2',
      'pie',
    ].map((t) => tester.getTopLeft(find.text(t)).dy).toList();
    expect(y, orderedEquals([...y]..sort()));
  });

  testWidgets('builds only the rows near the viewport', (tester) async {
    final construidas = await montar(tester, filas: 500);

    expect(construidas, isNotEmpty);
    expect(construidas.length, lessThan(30));
    expect(find.text('pie'), findsNothing);
  });

  testWidgets('semantic child count is the number of rows', (tester) async {
    await montar(tester, filas: 7);

    expect(
      tester.widget<ListView>(find.byType(ListView)).semanticChildCount,
      7,
    );
  });

  testWidgets('secciones lists static sections through a builder', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ListaPerezosa.secciones(secciones: [Text('uno'), Text('dos')]),
        ),
      ),
    );

    expect(find.text('uno'), findsOneWidget);
    expect(find.text('dos'), findsOneWidget);
    final lista = tester.widget<ListView>(find.byType(ListView));
    expect(lista.semanticChildCount, 2);
    expect(lista.childrenDelegate, isA<SliverChildBuilderDelegate>());
  });

  group('R3-007 row identity', () {
    Widget lista(List<int> ids) => MaterialApp(
      home: Scaffold(
        body: ListaPerezosa(
          cabecera: const [Text('cabecera')],
          cantidad: ids.length,
          idFila: (i) => ids[i],
          fila: (_, i) => _FilaConEstado(ids[i]),
        ),
      ),
    );

    testWidgets('removing a row keeps the state of the rows after it', (
      tester,
    ) async {
      await tester.pumpWidget(lista([1, 2, 3]));
      await tester.tap(find.text('fila 2 · 0'));
      await tester.pump();
      expect(find.text('fila 2 · 1'), findsOneWidget);

      await tester.pumpWidget(lista([1, 3]));

      expect(find.text('fila 3 · 0'), findsOneWidget);
      expect(find.text('fila 1 · 0'), findsOneWidget);

      await tester.pumpWidget(lista([2, 3]));
      expect(find.text('fila 2 · 0'), findsOneWidget);
    });

    testWidgets('removing an earlier row moves the state with its row', (
      tester,
    ) async {
      await tester.pumpWidget(lista([1, 2, 3]));
      await tester.tap(find.text('fila 2 · 0'));
      await tester.pump();

      await tester.pumpWidget(lista([2, 3]));

      expect(find.text('fila 2 · 1'), findsOneWidget);
      expect(find.text('fila 3 · 0'), findsOneWidget);
    });

    testWidgets('a keyed row is found at its index after the header', (
      tester,
    ) async {
      await tester.pumpWidget(lista([7, 8]));

      final delegado =
          tester.widget<ListView>(find.byType(ListView)).childrenDelegate
              as SliverChildBuilderDelegate;
      final buscar = delegado.findChildIndexCallback!;

      expect(buscar(const ValueKey('otra')), isNull);
      final claves = tester
          .widgetList<KeyedSubtree>(find.byType(KeyedSubtree))
          .map((w) => w.key)
          .whereType<ValueKey<Object>>()
          .toList();
      expect(claves.map(buscar), containsAll([1, 2]));
    });
  });
}

/// Counts its own taps, so a state reused by another row is visible.
class _FilaConEstado extends StatefulWidget {
  final int id;

  const _FilaConEstado(this.id);

  @override
  State<_FilaConEstado> createState() => _FilaConEstadoState();
}

class _FilaConEstadoState extends State<_FilaConEstado> {
  int _toques = 0;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => setState(() => _toques++),
    child: Text('fila ${widget.id} · $_toques'),
  );
}
