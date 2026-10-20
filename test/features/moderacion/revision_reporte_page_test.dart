import 'package:crowdradar/app/fakes/moderacion_repository_fake.dart';
import 'package:crowdradar/core/models/moderacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/features/moderacion/data/moderacion_repository.dart';
import 'package:crowdradar/features/moderacion/revision_reporte/revision_reporte_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements ModeracionRepository {}

void main() {
  bool? resultado;

  Future<void> abrir(
    WidgetTester tester,
    ModeracionRepository repo, {
    int id = 201,
  }) async {
    resultado = null;
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      RepositoryProvider<ModeracionRepository>.value(
        value: repo,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async => resultado = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RevisionReportePage(reporteId: id),
                  ),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  final dialogo = find.byType(AlertDialog);

  testWidgets('HU 7.1 c2 shows the report, its denuncias and the motivos', (
    tester,
  ) async {
    await abrir(tester, ModeracionRepositoryFake());

    expect(find.text('Reporte denunciado'), findsOneWidget);
    expect(find.text('Jockey Plaza'), findsOneWidget);
    expect(find.text('Reportado por Carlos M. · hace 1 h'), findsOneWidget);
    expect(find.text('carlos@correo.pe'), findsOneWidget);
    expect(find.text('Tranquilo'), findsOneWidget);
    expect(find.text('4 denuncias'), findsOneWidget);
    expect(find.text('MOTIVOS DE LA DENUNCIA'), findsOneWidget);
    expect(find.text('Información falsa'), findsOneWidget);
    expect(find.text('Contenido inapropiado'), findsOneWidget);
    expect(find.text('Spam o repetido'), findsOneWidget);
    expect(find.text('Mantener'), findsOneWidget);
    expect(find.text('Eliminar reporte'), findsOneWidget);
  });

  testWidgets(
    'HU 7.1 c3 eliminating asks to confirm and shows the new estado',
    (tester) async {
      await abrir(tester, ModeracionRepositoryFake());

      await tester.tap(find.text('Eliminar reporte'));
      await tester.pumpAndSettle();
      expect(dialogo, findsOneWidget);
      await tester.tap(
        find.descendant(of: dialogo, matching: find.text('Eliminar')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reporte eliminado'), findsOneWidget);
      expect(find.text('4 denuncias resueltas'), findsOneWidget);
    },
  );

  testWidgets('cancelling the confirmation sends nothing', (tester) async {
    await abrir(tester, ModeracionRepositoryFake());

    await tester.tap(find.text('Eliminar reporte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Mantener'), findsOneWidget);
    expect(find.text('Reporte eliminado'), findsNothing);
  });

  testWidgets('HU 7.1 c3 keeping the report passes the comentario', (
    tester,
  ) async {
    final repo = _MockRepo();
    registerFallbackValue(DecisionModeracion.mantener);
    final detalle = await ModeracionRepositoryFake().reporteDenunciado(201);
    when(() => repo.reporteDenunciado(201)).thenAnswer((_) async => detalle);
    when(
      () => repo.resolver(
        201,
        DecisionModeracion.mantener,
        comentario: 'Sin infracción',
      ),
    ).thenAnswer(
      (_) async => const ResolucionReporte(
        reporteId: 201,
        estado: EstadoReporteModerado.activo,
        denunciasResueltas: 4,
      ),
    );
    await abrir(tester, repo);

    await tester.enterText(find.byType(TextField), 'Sin infracción');
    await tester.tap(find.text('Mantener'));
    await tester.pumpAndSettle();

    verify(
      () => repo.resolver(
        201,
        DecisionModeracion.mantener,
        comentario: 'Sin infracción',
      ),
    ).called(1);
    expect(find.text('Reporte mantenido'), findsOneWidget);
  });

  testWidgets('Volver a la lista returns true so the queue drops the report', (
    tester,
  ) async {
    await abrir(tester, ModeracionRepositoryFake());
    await tester.tap(find.text('Mantener'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Volver a la lista'));
    await tester.pumpAndSettle();

    expect(resultado, isTrue);
  });

  testWidgets('a failed decision rolls back to the buttons with a notice', (
    tester,
  ) async {
    final repo = _MockRepo();
    registerFallbackValue(DecisionModeracion.mantener);
    final detalle = await ModeracionRepositoryFake().reporteDenunciado(201);
    when(() => repo.reporteDenunciado(201)).thenAnswer((_) async => detalle);
    when(
      () => repo.resolver(any(), any(), comentario: any(named: 'comentario')),
    ).thenThrow(const ApiException.sinConexion());
    await abrir(tester, repo);

    await tester.tap(find.text('Mantener'));
    await tester.pumpAndSettle();

    expect(find.text(ApiException.mensajeSinConexion), findsOneWidget);
    expect(find.text('Mantener'), findsOneWidget);
    expect(find.text('Eliminar reporte'), findsOneWidget);
  });

  testWidgets('a report already resolved shows the stale message', (
    tester,
  ) async {
    final repo = ModeracionRepositoryFake();
    await repo.resolver(201, DecisionModeracion.mantener);

    await abrir(tester, repo);

    expect(find.text('Reporte no encontrado'), findsOneWidget);
    expect(find.text('Volver a la lista'), findsOneWidget);
  });
}
