import 'package:crowdradar/app/fakes/karma_fake.dart';
import 'package:crowdradar/app/fakes/reporte_repository_fake.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/models/reporte_saturacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/network/respuesta_api.dart';
import 'package:crowdradar/features/reportes/data/reporte_repository.dart';
import 'package:crowdradar/features/reportes/reportar/reportar_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _RepoQueFalla implements ReporteRepository {
  final ApiException error;

  _RepoQueFalla(this.error);

  @override
  Future<ReporteCreado> reportar(int lugarId, NivelSaturacion nivel) async =>
      throw error;

  @override
  Future<Pagina<ReporteSaturacion>> listarMios({
    int page = 1,
    int size = 20,
  }) async => throw error;
}

void main() {
  late ReporteRepository repo;
  bool? resultado;

  Future<void> abrir(WidgetTester tester) async {
    resultado = null;
    tester.view.physicalSize = const Size(800, 2400);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      RepositoryProvider<ReporteRepository>.value(
        value: repo,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async => resultado = await mostrarReportarSheet(
                    context,
                    lugarId: 1,
                    lugarNombre: 'Parque Kennedy',
                  ),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  late ReporteRepositoryFake fake;

  setUp(() {
    fake = ReporteRepositoryFake(karma: KarmaFake(100));
    repo = fake;
  });

  testWidgets('shows the three HU 4.1 levels with their descriptions', (
    tester,
  ) async {
    await abrir(tester);

    expect(find.text('¿Qué tan lleno está?'), findsOneWidget);
    expect(find.text('Parque Kennedy'), findsOneWidget);
    expect(find.text('Tranquilo'), findsOneWidget);
    expect(find.text('Hay espacio, poca gente'), findsOneWidget);
    expect(find.text('Moderado'), findsOneWidget);
    expect(find.text('Algo concurrido'), findsOneWidget);
    expect(find.text('Saturado'), findsOneWidget);
    expect(find.text('Lleno, mucha gente'), findsOneWidget);
    expect(find.text('Enviar reporte'), findsOneWidget);
  });

  testWidgets(
    'sending without a level shows the validation and sends nothing',
    (tester) async {
      await abrir(tester);

      await tester.tap(find.text('Enviar reporte'));
      await tester.pump();

      expect(
        find.text('Selecciona un nivel de saturación para enviar tu reporte.'),
        findsOneWidget,
      );
      expect((await fake.listarMios()).items, isEmpty);
    },
  );

  testWidgets(
    'a successful report shows thanks and +10 karma, Listo returns true',
    (tester) async {
      await abrir(tester);

      await tester.tap(find.text('Moderado'));
      await tester.pump();
      await tester.tap(find.text('Enviar reporte'));
      await tester.pumpAndSettle();

      expect(find.text('¡Gracias por reportar!'), findsOneWidget);
      expect(
        find.text(
          'Tu reporte fue enviado correctamente y ya ayuda a otros ciudadanos.',
        ),
        findsOneWidget,
      );
      expect(find.text('+10 karma'), findsOneWidget);
      expect(
        (await fake.listarMios()).items.single.nivel,
        NivelSaturacion.moderado,
      );

      await tester.tap(find.text('Listo'));
      await tester.pumpAndSettle();

      expect(resultado, isTrue);
      expect(find.text('¡Gracias por reportar!'), findsNothing);
    },
  );

  testWidgets('when no points are awarded it says so with +0 karma', (
    tester,
  ) async {
    for (var lugar = 2; lugar <= 6; lugar++) {
      await fake.reportar(lugar, NivelSaturacion.moderado);
    }
    await abrir(tester);

    await tester.tap(find.text('Saturado'));
    await tester.pump();
    await tester.tap(find.text('Enviar reporte'));
    await tester.pumpAndSettle();

    expect(find.text('+0 karma'), findsOneWidget);
    expect(
      find.text(
        'No se otorgaron puntos por este reporte (tope diario alcanzado).',
      ),
      findsOneWidget,
    );
  });

  testWidgets('cooldown shows the HU message and lets the user close', (
    tester,
  ) async {
    await fake.reportar(1, NivelSaturacion.moderado);
    await abrir(tester);

    await tester.tap(find.text('Tranquilo'));
    await tester.pump();
    await tester.tap(find.text('Enviar reporte'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Ya enviaste un reporte para este lugar; vuelve a intentarlo en 30 '
        'minutos.',
      ),
      findsOneWidget,
    );
    expect(find.text('+10 karma'), findsNothing);
    expect(find.text('Enviar reporte'), findsOneWidget);
  });

  testWidgets('a blocking failure disables Enviar and offers to close', (
    tester,
  ) async {
    repo = _RepoQueFalla(
      const ApiException(
        status: 403,
        message: 'Tu cuenta está suspendida',
        code: 'CUENTA_SUSPENDIDA',
      ),
    );
    await abrir(tester);

    await tester.tap(find.text('Tranquilo'));
    await tester.pump();
    await tester.tap(find.text('Enviar reporte'));
    await tester.pumpAndSettle();

    expect(find.text('Tu cuenta está suspendida'), findsOneWidget);
    final enviar = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Enviar reporte'),
    );
    expect(enviar.onPressed, isNull);

    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();

    expect(find.text('Tu cuenta está suspendida'), findsNothing);
    expect(resultado, isNull);
  });

  testWidgets('an offline failure keeps the form and offers Reintentar', (
    tester,
  ) async {
    repo = _RepoQueFalla(const ApiException.sinConexion());
    await abrir(tester);

    await tester.tap(find.text('Tranquilo'));
    await tester.pump();
    await tester.tap(find.text('Enviar reporte'));
    await tester.pumpAndSettle();

    expect(find.text(ApiException.mensajeSinConexion), findsOneWidget);
    expect(find.text('Enviar reporte'), findsNothing);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.text('Cerrar'), findsNothing);
  });

  testWidgets('dismissing by the scrim after success still returns true', (
    tester,
  ) async {
    await abrir(tester);

    await tester.tap(find.text('Moderado'));
    await tester.pump();
    await tester.tap(find.text('Enviar reporte'));
    await tester.pumpAndSettle();
    expect(find.text('¡Gracias por reportar!'), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('¡Gracias por reportar!'), findsNothing);
    expect(resultado, isTrue);
  });

  testWidgets('dismissing without sending returns null', (tester) async {
    await abrir(tester);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(resultado, isNull);
  });
}
