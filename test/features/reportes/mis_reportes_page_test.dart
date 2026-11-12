import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/network/respuesta_api.dart';
import 'package:crowdradar/core/models/reporte_saturacion.dart';
import 'package:crowdradar/features/reportes/data/reporte_repository.dart';
import 'package:crowdradar/features/reportes/mis_reportes/mis_reportes_page.dart';
import 'package:crowdradar/core/models/validacion.dart';
import 'package:crowdradar/core/widgets/lista_perezosa.dart';
import 'package:crowdradar/features/validacion/data/validacion_repository.dart';
import 'package:crowdradar/features/validacion/widgets/chip_estado_validacion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../fakes/datos_lugares_fake.dart';
import '../../fakes/reporte_repository_fake.dart';
import '../validacion/json_validacion.dart';

class _MockValidacion extends Mock implements ValidacionRepository {}

void main() {
  Future<void> abrir(
    WidgetTester tester,
    ReporteRepository repo, {
    int size = 20,
    ValidacionRepository? validacion,
    double alto = 3200,
  }) async {
    tester.view.physicalSize = Size(800, alto);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      RepositoryProvider<ReporteRepository>.value(
        value: repo,
        child: MaterialApp(
          home: MisReportesPage(tamanoPagina: size, validacion: validacion),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('lists place, level and relative date of each report', (
    tester,
  ) async {
    final repo = ReporteRepositoryFake();
    await repo.reportar(1, NivelSaturacion.moderado);
    await repo.reportar(2, NivelSaturacion.saturado);
    await abrir(tester, repo);

    expect(find.text('Mis reportes'), findsOneWidget);
    for (final id in [1, 2]) {
      expect(
        find.text(lugaresFake.firstWhere((l) => l.id == id).nombre),
        findsOneWidget,
      );
    }
    expect(find.text('Saturado'), findsOneWidget);
    expect(find.text('Moderado'), findsOneWidget);
    expect(find.text('ahora'), findsNWidgets(2));
    // Fresh reports are not VALIDADO yet, so they carry no points (C4).
    expect(find.textContaining('+'), findsNothing);
  });

  testWidgets('each row shows its validation chip, matched by report id', (
    tester,
  ) async {
    final repo = ReporteRepositoryFake();
    await repo.reportar(1, NivelSaturacion.moderado);
    await repo.reportar(2, NivelSaturacion.saturado);
    final validacion = _MockValidacion();
    when(
      () => validacion.estadoMisReportes(size: any(named: 'size')),
    ).thenAnswer(
      (_) async => Pagina(
        items: [
          EstadoReporteValidacion.fromJson(
            estadoMioJson(id: 2, estado: 'VALIDADO'),
          ),
        ],
        page: 1,
        size: 50,
        total: 1,
        totalPaginas: 1,
      ),
    );
    await abrir(tester, repo, validacion: validacion);

    expect(find.byType(ChipEstadoValidacion), findsOneWidget);
    expect(find.text('Validado'), findsOneWidget);
  });

  group('S16 points per report', () {
    Finder filaDe(String lugar) =>
        find.ancestor(of: find.text(lugar), matching: find.byType(ListTile));

    testWidgets('a VALIDADO report shows +10', (tester) async {
      await abrir(tester, _ConItems([_reporte(1, 'Larcomar', puntos: 10)]));

      expect(
        find.descendant(of: filaDe('Larcomar'), matching: find.text('+10')),
        findsOneWidget,
      );
    });

    testWidgets('a report in another state shows no points', (tester) async {
      await abrir(
        tester,
        _ConItems([
          _reporte(2, 'Larcomar', puntos: 10),
          _reporte(1, 'Jockey Plaza', puntos: 0),
        ]),
      );

      expect(
        find.descendant(
          of: filaDe('Jockey Plaza'),
          matching: find.textContaining('+'),
        ),
        findsNothing,
      );
      expect(find.text('+0'), findsNothing);
      expect(find.text('+10'), findsOneWidget);
    });

    testWidgets('the retired daily-cap reason is never shown', (tester) async {
      await abrir(tester, _ConItems([_reporte(1, 'Larcomar', puntos: 0)]));

      expect(find.text('Tope diario alcanzado'), findsNothing);
      expect(find.text('Reporte eliminado'), findsNothing);
    });
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

  testWidgets('R3-009 Cargar más below the fold appends the next page', (
    tester,
  ) async {
    final repo = ReporteRepositoryFake();
    for (var lugar = 1; lugar <= 12; lugar++) {
      await repo.reportar(lugar, NivelSaturacion.tranquilo);
    }
    // 10 rows overflow this short screen, so the footer is built lazily.
    await abrir(tester, repo, size: 10, alto: 1200);
    expect(find.text('Cargar más'), findsNothing);
    final lista = find.descendant(
      of: find.byType(ListaPerezosa),
      matching: find.byType(Scrollable),
    );

    await tester.scrollUntilVisible(
      find.text('Cargar más'),
      300,
      scrollable: lista,
    );
    await tester.tap(find.text('Cargar más'));
    await tester.pump();
    await tester.pump();
    // The oldest report (place 1) arrives with the second page.
    final primero = lugaresFake.firstWhere((l) => l.id == 1).nombre;
    await tester.scrollUntilVisible(find.text(primero), 300, scrollable: lista);

    expect(find.text(primero), findsOneWidget);
    expect(find.text('Cargar más'), findsNothing);
  });
}

/// Fails the first call, then answers with an empty history.
ReporteSaturacion _reporte(int id, String lugar, {required int puntos}) =>
    ReporteSaturacion(
      id: id,
      lugarId: id,
      lugarNombre: lugar,
      nivel: NivelSaturacion.moderado,
      fechaHora: DateTime.now(),
      estado: 'ACTIVO',
      puntos: puntos,
    );

/// Serves [items] as the single page of "Mis reportes".
class _ConItems extends ReporteRepositoryFake {
  final List<ReporteSaturacion> items;

  _ConItems(this.items);

  @override
  Future<Pagina<ReporteSaturacion>> listarMios({
    int page = 1,
    int size = 20,
  }) async => Pagina(
    items: page == 1 ? items : const [],
    page: page,
    size: size,
    total: items.length,
    totalPaginas: 1,
  );
}

class _Intermitente extends ReporteRepositoryFake {
  int _llamadas = 0;

  @override
  Future<Pagina<ReporteSaturacion>> listarMios({
    int page = 1,
    int size = 20,
  }) async {
    if (_llamadas++ == 0) {
      throw const ApiException(status: 500, message: 'Servidor caído');
    }
    return super.listarMios(page: page, size: size);
  }
}
