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

    // The caption fills the screen, so the text sits inset by [relleno].
    final caja = tester.getRect(find.byType(EtiquetaSeccion));
    final texto = tester.getRect(find.text('SIN RESULTADOS'));
    expect(texto.left - caja.left, 16);
    expect(texto.top - caja.top, 12);
    expect(caja.right - texto.right, 16);
    expect(caja.bottom - texto.bottom, 4);
  });
}
