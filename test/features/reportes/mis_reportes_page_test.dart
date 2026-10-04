import 'package:crowdradar/app/fakes/datos_lugares_fake.dart';
import 'package:crowdradar/app/fakes/reporte_repository_fake.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/network/respuesta_api.dart';
import 'package:crowdradar/core/models/reporte_saturacion.dart';
import 'package:crowdradar/features/reportes/data/reporte_repository.dart';
import 'package:crowdradar/features/reportes/mis_reportes/mis_reportes_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> abrir(
    WidgetTester tester,
    ReporteRepository repo, {
    int size = 20,
  }) async {
    tester.view.physicalSize = const Size(800, 3200);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      RepositoryProvider<ReporteRepository>.value(
        value: repo,
        child: MaterialApp(home: MisReportesPage(tamanoPagina: size)),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('lists place, level, relative date and points of each report', (
    tester,
  ) async {
    final repo = ReporteRepositoryFake();
    await repo.reportar(1, NivelSaturacion.moderado);
    await repo.reportar(2, NivelSaturacion.saturado);
    await abrir(tester, repo);

    expect(find.text('Mis reportes'), findsOneWidget);
    for (final id in [1, 2]) {
      expect(find.text(lugaresFake.firstWhere((l) => l.id == id).nombre),
          findsOneWidget);
    }
    expect(find.text('Saturado'), findsOneWidget);
    expect(find.text('Moderado'), findsOneWidget);
    expect(find.text('ahora'), findsNWidgets(2));
    expect(find.text('+10'), findsNWidgets(2));
  });

  testWidgets('a report without karma shows +0 and the reason', (tester) async {
    final repo = ReporteRepositoryFake();
    for (var lugar = 1; lugar <= 6; lugar++) {
      await repo.reportar(lugar, NivelSaturacion.moderado);
    }
    await abrir(tester, repo);

    expect(find.text('+0'), findsOneWidget);
    expect(find.text('Tope diario alcanzado'), findsOneWidget);
  });

  testWidgets('no reports shows the HU 4.3 empty state', (tester) async {
    await abrir(tester, ReporteRepositoryFake());

    expect(find.text('Aún no tienes reportes'), findsOneWidget);
    expect(
      find.text(
        'Cuando reportes la saturación de un lugar, aparecerá aquí tu historial.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('an error shows the message and Reintentar reloads', (
    tester,
  ) async {
    final repo = _Intermitente();
    await abrir(tester, repo);
    expect(find.text('Servidor caído'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Servidor caído'), findsNothing);
    expect(find.text('Aún no tienes reportes'), findsOneWidget);
  });

  testWidgets('Cargar más appends the next page and then disappears', (
    tester,
  ) async {
    final repo = ReporteRepositoryFake();
    for (var lugar = 1; lugar <= 3; lugar++) {
      await repo.reportar(lugar, NivelSaturacion.tranquilo);
    }
    await abrir(tester, repo, size: 2);
    expect(find.byType(ListTile), findsNWidgets(2));

    await tester.tap(find.text('Cargar más'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(ListTile), findsNWidgets(3));
    expect(find.text('Cargar más'), findsNothing);
  });
}

/// Fails the first call, then answers with an empty history.
class _Intermitente extends ReporteRepositoryFake {
  int _llamadas = 0;

  @override
  Future<Pagina<ReporteSaturacion>> listarMios({int page = 1, int size = 20}) async {
    if (_llamadas++ == 0) {
      throw const ApiException(status: 500, message: 'Servidor caído');
    }
    return super.listarMios(page: page, size: size);
  }
}
