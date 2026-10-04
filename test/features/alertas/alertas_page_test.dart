import 'package:crowdradar/app/fakes/alerta_repository_fake.dart';
import 'package:crowdradar/app/fakes/comportamiento_fake.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/features/alertas/data/alerta_repository.dart';
import 'package:crowdradar/features/alertas/lista/alertas_cubit.dart';
import 'package:crowdradar/features/alertas/lista/alertas_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/enrutador_falso.dart';

void main() {
  Future<AlertasCubit> abrir(WidgetTester tester, AlertaRepository repo) async {
    tester.view.physicalSize = const Size(800, 3200);
    addTearDown(tester.view.resetPhysicalSize);
    final cubit = AlertasCubit(repo);
    addTearDown(cubit.close);
    await cubit.cargar();
    await tester.pumpWidget(
      BlocProvider<AlertasCubit>.value(
        value: cubit,
        child: MaterialApp.router(
          routerConfig: enrutadorDe(
            ruta: '/favoritos/alertas',
            inicial: '/favoritos/alertas',
            pantalla: const AlertasPage(),
            otras: const ['/mapa', '/mapa/lugares/1'],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return cubit;
  }

  testWidgets('lists each alert with title, levels, time and reason', (
    tester,
  ) async {
    await abrir(tester, AlertaRepositoryFake());

    expect(find.text('Alertas'), findsOneWidget);
    expect(find.text('Parque Kennedy ahora está Saturado'), findsOneWidget);
    expect(
      find.text('La saturación cambió de Moderado a Saturado ahora.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Recibes esta alerta porque Parque Kennedy está en tus favoritos.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Mercado de Surquillo ahora está Moderado'),
      findsOneWidget,
    );
    expect(find.text('Saturado'), findsOneWidget, reason: 'new level badge');
    expect(find.text('Tranquilo'), findsOneWidget, reason: 'old level badge');
    expect(find.text('Moderado'), findsNWidgets(2));
  });

  testWidgets('only the unread alert is highlighted', (tester) async {
    await abrir(tester, AlertaRepositoryFake());

    expect(find.byKey(const Key('no-leida-2')), findsOneWidget);
    expect(find.byKey(const Key('no-leida-1')), findsNothing);
  });

  testWidgets('tapping an unread alert marks it read and opens the place', (
    tester,
  ) async {
    final repo = AlertaRepositoryFake();
    final cubit = await abrir(tester, repo);

    await tester.tap(find.text('Parque Kennedy ahora está Saturado'));
    await tester.pumpAndSettle();

    expect(find.text('RUTA /mapa/lugares/1'), findsOneWidget);
    expect((await repo.listar()).noLeidas, 0);
    expect(cubit.noLeidas, 0);
  });

  testWidgets('tapping a read alert only opens the place', (tester) async {
    final repo = AlertaRepositoryFake();
    await abrir(tester, repo);

    await tester.tap(find.text('Mercado de Surquillo ahora está Moderado'));
    await tester.pumpAndSettle();

    expect((await repo.listar()).noLeidas, 1);
  });

  testWidgets('empty state says there are no alerts', (tester) async {
    await abrir(tester, AlertaRepositoryFake(sembrar: false));

    expect(find.text('No tienes alertas.'), findsOneWidget);
    expect(find.textContaining('ahora está'), findsNothing);
  });

  testWidgets('a new alert shows up when the page is opened again', (
    tester,
  ) async {
    final repo = AlertaRepositoryFake(sembrar: false);
    final cubit = await abrir(tester, repo);
    expect(find.text('No tienes alertas.'), findsOneWidget);

    repo.emitir(3, NivelSaturacion.tranquilo, NivelSaturacion.saturado);
    await cubit.refrescar();
    await tester.pump();
    await tester.pump();

    expect(find.text('Playa Costa Verde ahora está Saturado'), findsOneWidget);
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

    expect(find.text('Parque Kennedy ahora está Saturado'), findsOneWidget);
  });
}

/// Fails the first listing, then answers like the seeded fake.
class _Intermitente extends AlertaRepositoryFake {
  bool _fallo = true;

  @override
  Future<PaginaAlertas> listar({int page = 1, int size = 20}) {
    if (_fallo) {
      _fallo = false;
      return AlertaRepositoryFake(
        comportamiento: const ComportamientoFake(
          fallo: ApiException(status: 500, message: 'Servidor caído'),
        ),
      ).listar();
    }
    return super.listar(page: page, size: size);
  }
}
