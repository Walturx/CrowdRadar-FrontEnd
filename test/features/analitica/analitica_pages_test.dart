import 'package:crowdradar/app/fakes/analitica_repository_fake.dart';
import 'package:crowdradar/core/models/analitica.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/features/analitica/comparar/comparar_page.dart';
import 'package:crowdradar/features/analitica/data/analitica_repository.dart';
import 'package:crowdradar/features/analitica/historial/historial_page.dart';
import 'package:crowdradar/features/analitica/mejor_horario/mejor_horario_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/enrutador_falso.dart';

const _conDatos = 1;
const _sinDatos = 9999;

void main() {
  Future<void> abrir(
    WidgetTester tester,
    Widget pagina, {
    AnaliticaRepository? repo,
    List<String> otras = const [],
  }) async {
    tester.view.physicalSize = const Size(800, 3200);
    addTearDown(tester.view.resetPhysicalSize);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      RepositoryProvider<AnaliticaRepository>.value(
        value: repo ?? AnaliticaRepositoryFake(),
        child: MaterialApp.router(
          routerConfig: enrutadorDe(
            ruta: '/actual',
            inicial: '/actual',
            pantalla: pagina,
            otras: otras,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  group('HistorialPage', () {
    testWidgets('shows the hourly chart flagged as demo data (HU 6.1 c1)', (
      tester,
    ) async {
      await abrir(tester, const HistorialPage(lugarId: _conDatos));

      expect(find.text('Historial de aforo'), findsOneWidget);
      expect(find.text('SATURACIÓN POR HORA · HOY'), findsOneWidget);
      expect(find.byKey(const Key('barra-saturacion')), findsNWidgets(24));
      expect(find.text('Datos de demostración'), findsOneWidget);
    });

    testWidgets('the 7 day option groups by day', (tester) async {
      await abrir(tester, const HistorialPage(lugarId: _conDatos));

      await tester.tap(find.text('7 días'));
      await tester.pump();
      await tester.pump();

      expect(find.text('SATURACIÓN POR DÍA · ÚLTIMOS 7 DÍAS'), findsOneWidget);
      expect(find.byKey(const Key('barra-saturacion')), findsNWidgets(7));
    });

    testWidgets('a place without history shows the HU 6.1 c3 message', (
      tester,
    ) async {
      await abrir(tester, const HistorialPage(lugarId: _sinDatos));

      expect(find.text('Sin historial todavía'), findsOneWidget);
      expect(
        find.text(
          'No existe información histórica disponible para este lugar.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('barra-saturacion')), findsNothing);
      expect(find.text('Datos de demostración'), findsNothing);
    });

    testWidgets('an error shows the message and Reintentar reloads', (
      tester,
    ) async {
      await abrir(
        tester,
        const HistorialPage(lugarId: _conDatos),
        repo: _Intermitente(),
      );
      expect(find.text('Servidor caído'), findsOneWidget);

      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Servidor caído'), findsNothing);
      expect(find.byKey(const Key('barra-saturacion')), findsNWidgets(24));
    });

    testWidgets('links to the comparison and the best time', (tester) async {
      await abrir(
        tester,
        const HistorialPage(lugarId: _conDatos),
        otras: const [
          '/mapa/lugares/1/comparar',
          '/mapa/lugares/1/mejor-horario',
        ],
      );

      await tester.tap(find.text('Comparar periodos'));
      await tester.pumpAndSettle();
      expect(find.text('RUTA /mapa/lugares/1/comparar'), findsOneWidget);
    });
  });

  group('CompararPage', () {
    testWidgets('discloses demo data when the backend flags it top-level', (
      tester,
    ) async {
      await abrir(
        tester,
        const CompararPage(lugarId: _conDatos),
        repo: _CompararDelBackend(),
      );

      expect(find.byKey(const Key('barra-saturacion')), findsNWidgets(48));
      expect(find.text('Datos de demostración'), findsOneWidget);
    });

    testWidgets('shows both periods and the summary (HU 6.2 c1)', (
      tester,
    ) async {
      await abrir(tester, const CompararPage(lugarId: _conDatos));

      expect(find.text('Comparar periodos'), findsOneWidget);
      expect(find.text('ENTRE SEMANA'), findsOneWidget);
      expect(find.text('FIN DE SEMANA'), findsOneWidget);
      expect(find.byKey(const Key('barra-saturacion')), findsNWidgets(48));
      expect(find.textContaining('fines de semana'), findsOneWidget);
      expect(find.text('Datos de demostración'), findsOneWidget);
    });

    testWidgets('insufficient data shows the HU 6.2 c3 message', (
      tester,
    ) async {
      await abrir(tester, const CompararPage(lugarId: _sinDatos));

      expect(find.text('Sin datos suficientes'), findsOneWidget);
      expect(
        find.text('No existen datos suficientes para realizar la comparación.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('barra-saturacion')), findsNothing);
    });
  });

  group('MejorHorarioPage', () {
    testWidgets('highlights the best time to visit (HU 6.3 c1)', (
      tester,
    ) async {
      await abrir(tester, const MejorHorarioPage(lugarId: _conDatos));

      expect(find.text('Mejor horario'), findsOneWidget);
      expect(find.text('MEJOR HORA PARA VISITAR'), findsOneWidget);
      expect(
        find.text(
          'Es el horario con menor afluencia. Planifica tu visita entonces.',
        ),
        findsOneWidget,
      );
      expect(find.text('Datos de demostración'), findsOneWidget);
    });

    testWidgets('no recommendation shows the HU 6.3 c3 message', (
      tester,
    ) async {
      await abrir(tester, const MejorHorarioPage(lugarId: _sinDatos));

      expect(find.text('Sin recomendación todavía'), findsOneWidget);
      expect(
        find.text(
          'No existen datos suficientes para generar la recomendación.',
        ),
        findsOneWidget,
      );
      expect(find.text('MEJOR HORA PARA VISITAR'), findsNothing);
    });
  });
}

/// Fails the first history call, then answers normally.
class _Intermitente extends AnaliticaRepositoryFake {
  int _llamadas = 0;

  @override
  Future<SerieSaturacion> historial(
    int lugarId, {
    DateTime? desde,
    DateTime? hasta,
    AgrupacionHistorial? agrupacion,
  }) {
    if (_llamadas++ == 0) {
      throw const ApiException(status: 500, message: 'Servidor caído');
    }
    return super.historial(
      lugarId,
      desde: desde,
      hasta: hasta,
      agrupacion: agrupacion,
    );
  }
}

/// Serves `comparar` through the parser with a backend-shaped body: the
/// `sintetico` flag lives at the top level, the periods are plain lists.
class _CompararDelBackend extends AnaliticaRepositoryFake {
  @override
  Future<ComparacionPeriodos> comparar(
    int lugarId, {
    required DateTime desdeA,
    required DateTime hastaA,
    required DateTime desdeB,
    required DateTime hastaB,
    String? diasA,
    String? diasB,
  }) async {
    List<Map<String, Object?>> dia(double v) => [
      for (var h = 0; h < 24; h++) {'hora': h, 'valor': v, 'muestras': 3},
    ];
    return ComparacionPeriodos.fromJson({
      'periodoA': dia(1),
      'periodoB': dia(2),
      'diferencias': [
        for (var h = 0; h < 24; h++) {'hora': h, 'diferencia': 1.0},
      ],
      'resumen': 'Los fines de semana la afluencia sube.',
      'suficiente': true,
      'mensaje': null,
      'sintetico': true,
    });
  }
}
