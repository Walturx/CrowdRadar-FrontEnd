import 'package:crowdradar/core/widgets/etiqueta_seccion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the section text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: EtiquetaSeccion('INFORMACIÓN')),
    );

    expect(find.text('INFORMACIÓN'), findsOneWidget);
  });

  testWidgets('padding is configurable', (tester) async {
    const relleno = EdgeInsets.fromLTRB(16, 12, 16, 4);
    await tester.pumpWidget(
      const MaterialApp(
        home: EtiquetaSeccion('SIN RESULTADOS', relleno: relleno),
      ),
    );

    final padding = tester.widget<Padding>(
      find
          .ancestor(
            of: find.text('SIN RESULTADOS'),
            matching: find.byType(Padding),
          )
          .first,
    );
    expect(padding.padding, relleno);
  });
}
