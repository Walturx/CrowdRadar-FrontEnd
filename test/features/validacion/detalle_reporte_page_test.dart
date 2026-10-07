import 'package:crowdradar/app/fakes/validacion_repository_fake.dart';
import 'package:crowdradar/core/models/validacion.dart';
import 'package:crowdradar/features/validacion/data/validacion_repository.dart';
import 'package:crowdradar/features/validacion/detalle_reporte/detalle_reporte_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ValidacionRepositoryFake repo;

  Future<void> abrir(WidgetTester tester, int id) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      RepositoryProvider<ValidacionRepository>.value(
        value: repo,
        child: MaterialApp(home: DetalleReportePage(reporteId: id)),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() => repo = ValidacionRepositoryFake());

  testWidgets('ALTA shows the percentage, level and raw counts', (
    tester,
  ) async {
    await abrir(tester, 101);

    expect(find.text('Detalle del reporte'), findsOneWidget);
    expect(find.text('Parque Kennedy'), findsOneWidget);
    expect(find.text('CONFIABILIDAD DEL REPORTE'), findsOneWidget);
    expect(find.text('86%'), findsOneWidget);
    expect(find.text('Confiabilidad Alta'), findsOneWidget);
    expect(find.text('18 confirman'), findsOneWidget);
    expect(find.text('3 rechazan'), findsOneWidget);
    expect(
      find.text('Basado en confirmaciones de la comunidad'),
      findsOneWidget,
    );
  });

  testWidgets('BAJA warns to take the report with caution', (tester) async {
    await abrir(tester, 104);

    expect(find.text('38%'), findsOneWidget);
    expect(find.text('Confiabilidad Baja'), findsOneWidget);
    expect(
      find.text(
        'Este reporte tiene pocas confirmaciones. Tómalo con precaución.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('INSUFICIENTE says there is not enough information', (
    tester,
  ) async {
    await abrir(tester, 102);

    expect(
      find.text(
        'Aún no hay información suficiente para determinar la confiabilidad.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('voting thanks with +2 karma and then shows my vote', (
    tester,
  ) async {
    await abrir(tester, 101);

    await tester.tap(find.text('Rechazar'));
    await tester.pumpAndSettle();

    expect(find.text('¡Gracias por validar! +2 karma'), findsOneWidget);
    expect(find.text('Tu voto: Rechazaste este reporte'), findsOneWidget);
    expect(find.text('Confirmar'), findsNothing);
    expect(find.text('4 rechazan'), findsOneWidget);
  });

  testWidgets('an already voted report shows my vote on a later visit', (
    tester,
  ) async {
    await repo.validar(101, TipoAccionValidacion.confirmar);
    await abrir(tester, 101);

    expect(find.text('Tu voto: Confirmaste este reporte'), findsOneWidget);
  });

  testWidgets('my own report offers neither voting nor reporting', (
    tester,
  ) async {
    await abrir(tester, ValidacionRepositoryFake.idReportePropio);

    expect(find.text('Confirmar'), findsNothing);
    expect(find.text('Denunciar reporte fraudulento'), findsNothing);
  });

  testWidgets(
    'reporting: needs a motivo, then confirms and marks it reported',
    (tester) async {
      await abrir(tester, 101);

      await tester.tap(find.text('Denunciar reporte fraudulento'));
      await tester.pumpAndSettle();
      expect(find.text('¿Por qué lo denuncias?'), findsOneWidget);
      expect(
        find.text('Tu denuncia será revisada por el equipo de moderación.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Enviar denuncia'));
      await tester.pumpAndSettle();
      expect(
        find.text('Selecciona un motivo para enviar tu denuncia.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Spam o repetido'));
      await tester.tap(find.text('Enviar denuncia'));
      await tester.pumpAndSettle();
      expect(find.text('Denuncia enviada'), findsOneWidget);
      expect(
        find.text(
          'Gracias por avisar. El equipo de moderación revisará este reporte.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Listo'));
      await tester.pumpAndSettle();
      expect(find.text('Ya denunciaste este reporte'), findsOneWidget);
      expect(find.text('Denunciar reporte fraudulento'), findsNothing);
    },
  );

  testWidgets('a report that does not exist shows the error', (tester) async {
    await abrir(tester, 9999);

    expect(find.text('Reporte no encontrado'), findsOneWidget);
  });
}
