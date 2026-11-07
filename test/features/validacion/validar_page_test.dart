import 'package:crowdradar/app/fakes/comportamiento_fake.dart';
import 'package:crowdradar/app/fakes/validacion_repository_fake.dart';
import 'package:crowdradar/core/location/punto_referencia.dart';
import 'package:crowdradar/core/map/centro_compartido.dart';
import 'package:crowdradar/core/models/validacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/network/respuesta_api.dart';
import 'package:crowdradar/features/validacion/data/validacion_repository.dart';
import 'package:crowdradar/features/validacion/pendientes/validar_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/ubicacion_fake.dart';
import 'json_validacion.dart';

class _MockRepo extends Mock implements ValidacionRepository {}

/// The row that holds the "¡Gracias por validar!" title.
Finder _filaGracias() => find
    .ancestor(
      of: find.text('¡Gracias por validar!'),
      matching: find.byType(Row),
    )
    .first;

/// Any tier badge image, or the one at [ruta].
Finder _insigniaTier([String? ruta]) => find.byWidgetPredicate(
  (w) =>
      w is Image &&
      w.image is AssetImage &&
      (ruta == null
          ? (w.image as AssetImage).assetName.startsWith('assets/images/tier_')
          : (w.image as AssetImage).assetName == ruta),
);

void main() {
  Future<void> abrir(
    WidgetTester tester,
    ValidacionRepository repo, {
    bool conUbicacion = true,
  }) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      RepositoryProvider<ValidacionRepository>.value(
        value: repo,
        child: MaterialApp(
          home: ValidarPage(
            referencia: PuntoReferencia(
              UbicacionServiceFake(conUbicacion ? miraflores : null),
              CentroMapaCompartido(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('shows the nearest pending report with its reliability', (
    tester,
  ) async {
    await abrir(tester, ValidacionRepositoryFake());

    expect(find.text('Validar reportes'), findsOneWidget);
    expect(find.text('Parque Kennedy'), findsOneWidget);
    expect(find.text('400 m'), findsOneWidget);
    expect(find.text('Saturado'), findsOneWidget);
    expect(find.textContaining('Confiabilidad Alta'), findsOneWidget);
    expect(find.text('Confirmar'), findsOneWidget);
    expect(find.text('Rechazar'), findsOneWidget);
  });

  testWidgets('S15 confirming thanks the user without points and advances', (
    tester,
  ) async {
    await abrir(tester, ValidacionRepositoryFake());

    await tester.tap(find.text('Confirmar'));
    await tester.pump();
    await tester.pump();

    expect(find.text('¡Gracias por validar!'), findsOneWidget);
    expect(
      find.textContaining(RegExp(r'\+\d|puntos|karma', caseSensitive: false)),
      findsNothing,
    );
    expect(find.textContaining('Confirmaste'), findsOneWidget);
    expect(find.text('Mercado de Surquillo'), findsOneWidget);
    expect(find.text('Parque Kennedy'), findsNothing);
  });

  testWidgets('S15 S23 a vote with no tier shows the thanks alone, without a '
      'daily cap or points', (tester) async {
    registerFallbackValue(TipoAccionValidacion.confirmar);
    final repo = _MockRepo();
    when(
      () => repo.pendientes(
        lat: any(named: 'lat'),
        lng: any(named: 'lng'),
      ),
    ).thenAnswer(
      (_) async => Pagina(
        items: [ReportePendiente.fromJson(pendienteJson(id: 1))],
        page: 1,
        size: 20,
        total: 1,
        totalPaginas: 1,
      ),
    );
    when(() => repo.validar(any(), any())).thenAnswer(
      (_) async => const ResultadoVoto(
        accion: TipoAccionValidacion.confirmar,
        confiabilidad: Confiabilidad(
          porcentaje: 80,
          nivel: NivelConfiabilidad.alta,
        ),
        estadoValidacion: EstadoValidacion.enValidacion,
      ),
    );
    await abrir(tester, repo);

    await tester.tap(find.text('Confirmar'));
    await tester.pump();
    await tester.pump();

    expect(find.text('¡Gracias por validar!'), findsOneWidget);
    expect(find.textContaining('Voto registrado'), findsNothing);
    expect(find.textContaining('máximo'), findsNothing);
    expect(
      find.textContaining(RegExp(r'\+\d|puntos|karma', caseSensitive: false)),
      findsNothing,
    );
    // S23: a response without `usuario` (older backend) shows no tier.
    expect(find.textContaining('Crowd '), findsNothing);
    expect(_insigniaTier(), findsNothing);
  });

  testWidgets('S23 the thanks shows the voter tier beside it (C7)', (
    tester,
  ) async {
    await abrir(tester, ValidacionRepositoryFake());

    await tester.tap(find.text('Rechazar'));
    await tester.pump();
    await tester.pump();

    expect(find.text('¡Gracias por validar!'), findsOneWidget);
    expect(
      find.descendant(
        of: _filaGracias(),
        matching: find.text('Crowd Explorer'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: _filaGracias(),
        matching: _insigniaTier('assets/images/tier_crowd_explorer.png'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Rechazaste'), findsOneWidget);
  });

  testWidgets('after the last report the empty state appears', (tester) async {
    await abrir(tester, ValidacionRepositoryFake());

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Rechazar'));
      await tester.pumpAndSettle();
    }

    expect(find.text('No hay reportes por validar'), findsOneWidget);
  });

  testWidgets('an offline load shows the error with a retry', (tester) async {
    await abrir(
      tester,
      ValidacionRepositoryFake(
        comportamiento: const ComportamientoFake(
          fallo: ApiException.sinConexion(),
        ),
      ),
    );

    expect(find.text('Reintentar'), findsOneWidget);
  });

  group('CRO-65 where the reports are searched', () {
    _MockRepo vacio() {
      final repo = _MockRepo();
      when(
        () => repo.pendientes(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
        ),
      ).thenAnswer(
        (_) async => const Pagina<ReportePendiente>(
          items: [],
          page: 1,
          size: 20,
          total: 0,
          totalPaginas: 1,
        ),
      );
      return repo;
    }

    testWidgets('S1 with the device location there is no map-centre notice', (
      tester,
    ) async {
      await abrir(tester, ValidacionRepositoryFake());

      expect(find.text('Parque Kennedy'), findsOneWidget);
      expect(find.text(ValidarPage.avisoCentroMapa), findsNothing);
    });

    testWidgets('S2 without the location it says the map centre is used', (
      tester,
    ) async {
      await abrir(tester, ValidacionRepositoryFake(), conUbicacion: false);

      expect(find.text(ValidarPage.avisoCentroMapa), findsOneWidget);
      expect(find.text('Parque Kennedy'), findsOneWidget);
    });

    testWidgets('S2 the empty state names the map centre too', (tester) async {
      await abrir(tester, vacio(), conUbicacion: false);

      expect(find.text(ValidarPage.tituloVacio), findsOneWidget);
      expect(find.text(ValidarPage.mensajeVacioCentroMapa), findsOneWidget);
      expect(find.text(ValidarPage.mensajeVacio), findsNothing);
    });

    testWidgets('S1 the empty state near the user keeps its message', (
      tester,
    ) async {
      await abrir(tester, vacio());

      expect(find.text(ValidarPage.mensajeVacio), findsOneWidget);
      expect(find.text(ValidarPage.avisoCentroMapa), findsNothing);
    });
  });
}
