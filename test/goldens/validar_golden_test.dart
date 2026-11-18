import 'package:crowdradar/core/location/punto_referencia.dart';
import 'package:crowdradar/core/map/centro_compartido.dart';
import 'package:crowdradar/core/models/validacion.dart';
import 'package:crowdradar/core/network/respuesta_api.dart';
import 'package:crowdradar/features/validacion/data/validacion_repository.dart';
import 'package:crowdradar/features/validacion/pendientes/validar_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../fakes/validacion_repository_fake.dart';
import '../helpers/ubicacion_fake.dart';
import 'golden_harness.dart';

class _ValidacionRepoMock extends Mock implements ValidacionRepository {}

void main() {
  Future<void> open(WidgetTester tester, ValidacionRepository repo) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(
      RepositoryProvider<ValidacionRepository>.value(
        value: repo,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: appTheme,
          builder: withoutAnimations,
          home: ValidarPage(
            referencia: PuntoReferencia(
              UbicacionServiceFake(miraflores),
              CentroMapaCompartido(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await loadImages(tester);
  }

  testWidgets('validate, list of pending reports', (tester) async {
    // The fake stamps its reports with the current time, so they read "ahora".
    await open(tester, ValidacionRepositoryFake());

    expect(find.text('Validar reportes'), findsOneWidget);
    await matchBaseline('validar_lista');
  });

  testWidgets('validate, nothing to validate', (tester) async {
    final repo = _ValidacionRepoMock();
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
    await open(tester, repo);

    expect(find.text('No hay reportes por validar'), findsOneWidget);
    await matchBaseline('validar_vacio');
  });
}
