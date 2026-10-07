import 'package:crowdradar/app/fakes/validacion_repository_fake.dart';
import 'package:crowdradar/core/models/validacion.dart';
import 'package:crowdradar/core/network/respuesta_api.dart';
import 'package:crowdradar/features/validacion/data/validacion_repository.dart';
import 'package:crowdradar/features/validacion/estado/estado_validacion_page.dart';
import 'package:crowdradar/features/validacion/widgets/chip_estado_validacion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'json_validacion.dart';

class _MockRepo extends Mock implements ValidacionRepository {}

void main() {
  Future<void> abrir(WidgetTester tester, ValidacionRepository repo) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      RepositoryProvider<ValidacionRepository>.value(
        value: repo,
        child: const MaterialApp(home: EstadoValidacionPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists my reports with estado and counts, with the filters', (
    tester,
  ) async {
    await abrir(tester, ValidacionRepositoryFake());

    expect(find.text('Estado de mis reportes'), findsOneWidget);
    for (final f in ['Todos', 'Validados', 'En validación', 'Rechazados']) {
      expect(find.widgetWithText(ChoiceChip, f), findsOneWidget);
    }
    expect(find.text('Parque Kennedy'), findsOneWidget);
    expect(find.text('2 confirman · 1 rechazan'), findsOneWidget);
    expect(find.byType(ChipEstadoValidacion), findsOneWidget);
  });

  testWidgets('a filter without matches says so', (tester) async {
    await abrir(tester, ValidacionRepositoryFake());

    await tester.tap(find.widgetWithText(ChoiceChip, 'Validados'));
    await tester.pumpAndSettle();

    expect(find.text('Parque Kennedy'), findsNothing);
    expect(find.text('No hay reportes con este estado.'), findsOneWidget);
  });

  testWidgets('a report nobody voted says there are no validations yet', (
    tester,
  ) async {
    final repo = _MockRepo();
    when(() => repo.estadoMisReportes(size: any(named: 'size'))).thenAnswer(
      (_) async => Pagina(
        items: [
          EstadoReporteValidacion.fromJson(
            estadoMioJson(estado: 'SIN_VALIDACIONES'),
          ),
        ],
        page: 1,
        size: 50,
        total: 1,
        totalPaginas: 1,
      ),
    );
    await abrir(tester, repo);

    expect(
      find.text('Todavía no existen validaciones registradas.'),
      findsOneWidget,
    );
  });

  testWidgets('chip labels follow the estado', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            for (final e in EstadoValidacion.values)
              ChipEstadoValidacion(estado: e),
          ],
        ),
      ),
    );

    for (final t in [
      'Validado',
      'En validación',
      'Rechazado',
      'Sin validaciones',
    ]) {
      expect(find.text(t), findsOneWidget);
    }
  });
}
