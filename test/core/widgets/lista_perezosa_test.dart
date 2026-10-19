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
}
