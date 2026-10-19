import 'package:crowdradar/app/fakes/comportamiento_fake.dart';
import 'package:crowdradar/app/fakes/moderacion_repository_fake.dart';
import 'package:crowdradar/core/models/moderacion.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/models/validacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/network/respuesta_api.dart';
import 'package:crowdradar/core/widgets/lista_perezosa.dart';
import 'package:crowdradar/features/moderacion/data/moderacion_repository.dart';
import 'package:crowdradar/features/moderacion/denunciados/denunciados_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  String? abierto;

  Future<void> abrir(WidgetTester tester, ModeracionRepository repo) async {
    abierto = null;
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      RepositoryProvider<ModeracionRepository>.value(
        value: repo,
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(path: '/', builder: (_, _) => const DenunciadosPage()),
              GoRoute(
                path: '/admin/reportes/:id',
                builder: (context, s) {
                  abierto = s.pathParameters['id'];
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () async {
                        await repo.resolver(
                          int.parse(abierto!),
                          DecisionModeracion.eliminar,
                        );
                        if (context.mounted) context.pop(true);
                      },
                      child: const Text('resolver'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('HU 7.1 c1 lists the reported reports with their counts', (
    tester,
  ) async {
    await abrir(tester, ModeracionRepositoryFake());

    expect(find.text('Reportes denunciados'), findsOneWidget);
    expect(find.text('3 REPORTES POR REVISAR'), findsOneWidget);
    expect(find.text('Jockey Plaza'), findsOneWidget);
    expect(find.text('Carlos M. · hace 1 h'), findsOneWidget);
    expect(find.text('Tranquilo'), findsOneWidget);
    expect(find.text('4 denuncias'), findsOneWidget);
    expect(find.text('Larcomar'), findsOneWidget);
    expect(find.text('2 denuncias'), findsOneWidget);
    expect(find.text('Revisar'), findsNWidgets(3));
  });

  testWidgets('HU 7.1 c3 an empty queue shows the empty state', (tester) async {
    final repo = ModeracionRepositoryFake();
    for (final r in (await repo.reportesDenunciados()).items) {
      await repo.resolver(r.reporteId, DecisionModeracion.mantener);
    }

    await abrir(tester, repo);

    expect(find.text('Sin denuncias pendientes'), findsOneWidget);
    expect(
      find.text(
        'No hay reportes denunciados por revisar. ¡La comunidad está al día!',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Revisar opens the review of that report', (tester) async {
    await abrir(tester, ModeracionRepositoryFake());

    await tester.tap(find.text('Revisar').first);
    await tester.pumpAndSettle();

    expect(abierto, '201');
  });

  testWidgets('a report resolved on the review screen leaves the list', (
    tester,
  ) async {
    await abrir(tester, ModeracionRepositoryFake());

    await tester.tap(find.text('Revisar').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('resolver'));
    await tester.pumpAndSettle();

    expect(find.text('2 REPORTES POR REVISAR'), findsOneWidget);
    expect(find.text('Jockey Plaza'), findsNothing);
  });

  testWidgets('an offline load shows the error with a retry', (tester) async {
    await abrir(
      tester,
      ModeracionRepositoryFake(
        comportamiento: const ComportamientoFake(
          fallo: ApiException.sinConexion(),
        ),
      ),
    );

    expect(find.text(ApiException.mensajeSinConexion), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  group('R3-009 lazy list', () {
    testWidgets('pull-to-refresh reloads the queue', (tester) async {
      final repo = _DenunciadosPaginados(3);
      await abrir(tester, repo);
      expect(find.text('3 REPORTES POR REVISAR'), findsOneWidget);

      repo.total = 4;
      await tester.fling(
        find.text('3 REPORTES POR REVISAR'),
        // Past a quarter of the (2400 px) viewport, the refresh threshold.
        const Offset(0, 1000),
        1000,
      );
      await tester.pumpAndSettle();

      expect(repo.llamadas, 2);
      expect(find.text('4 REPORTES POR REVISAR'), findsOneWidget);
      expect(find.text('Lugar 4'), findsOneWidget);
    });

    testWidgets('Cargar más below the fold appends the next page', (
      tester,
    ) async {
      final repo = _DenunciadosPaginados(25);
      await abrir(tester, repo);
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
      await tester.scrollUntilVisible(
        find.text('Lugar 25'),
        300,
        scrollable: lista,
      );

      expect(repo.llamadas, 2);
      expect(find.text('Lugar 25'), findsOneWidget);
      expect(find.text('Cargar más'), findsNothing);
    });
  });
}

/// Serves [total] generated reports in pages, counting the calls.
class _DenunciadosPaginados extends ModeracionRepositoryFake {
  int total;
  int llamadas = 0;

  _DenunciadosPaginados(this.total);

  @override
  Future<Pagina<ReporteDenunciado>> reportesDenunciados({
    int page = 1,
    int size = 20,
  }) async {
    llamadas++;
    return Pagina(
      items: [
        for (var i = (page - 1) * size + 1; i <= total && i <= page * size; i++)
          ReporteDenunciado(
            reporteId: i,
            lugar: LugarReporte(id: i, nombre: 'Lugar $i'),
            autor: AutorModerado(id: i, nombre: 'Autor', apellido: '$i'),
            nivel: NivelSaturacion.tranquilo,
            pendientes: 1,
          ),
      ],
      page: page,
      size: size,
      total: total,
      totalPaginas: (total + size - 1) ~/ size,
    );
  }
}
