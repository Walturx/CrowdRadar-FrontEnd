import 'package:crowdradar/core/widgets/estado_vacio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders icon, title and subtitle', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: EstadoVacio(
        icon: Icons.favorite_border,
        title: 'Título',
        subtitle: 'Detalle',
      ),
    ));

    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    expect(find.text('Título'), findsOneWidget);
    expect(find.text('Detalle'), findsOneWidget);
  });
}
