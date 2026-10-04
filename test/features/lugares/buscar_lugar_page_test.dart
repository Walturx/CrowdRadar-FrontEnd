import 'package:crowdradar/core/map/tipos_mapa.dart';
import 'package:crowdradar/core/models/categoria_lugar.dart';
import 'package:crowdradar/core/models/lugar_resumen.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/features/lugares/buscar/buscar_lugar_page.dart';
import 'package:crowdradar/features/lugares/data/lugar_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:crowdradar/app/rutas.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/lugar_repo_falso.dart';

const _kennedy = LugarResumen(
  id: 1,
  nombre: 'Parque Kennedy',
  categoria: CategoriaLugar.parque,
  latitud: -12.1219,
  longitud: -77.0297,
  saturacion: NivelSaturacion.moderado,
);
const _exposicion = LugarResumen(
  id: 4,
  nombre: 'Parque de la Exposición',
  categoria: CategoriaLugar.parque,
  latitud: -12.0690,
  longitud: -77.0360,
  saturacion: NivelSaturacion.tranquilo,
);

/// 316 m from Parque Kennedy.
const _centro = PuntoGeografico(-12.1219, -77.0268);
const _hint = 'Escribe al menos 2 caracteres para buscar';

void main() {
  late RepoLugarFalso repo;
  int? elegido;

  Future<void> abrir(
    WidgetTester tester, {
    PuntoGeografico? centro = _centro,
  }) async {
    elegido = null;
    await tester.pumpWidget(
      RepositoryProvider<LugarRepository>.value(
        value: repo,
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => Builder(
                  builder: (context) => TextButton(
                    onPressed: () async {
                      elegido = await context.push<int>(
                        Rutas.buscarLugar,
                        extra: centro,
                      );
                    },
                    child: const Text('Abrir'),
                  ),
                ),
              ),
              GoRoute(
                path: Rutas.buscarLugar,
                builder: (_, s) => BuscarLugarPage(
                  centroMapa: s.extra is PuntoGeografico
                      ? s.extra as PuntoGeografico
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  Future<void> escribir(WidgetTester tester, String texto) async {
    await tester.enterText(find.byType(TextField), texto);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
  }

  group('hint', () {
    testWidgets(
      'shows the hint at first and for fewer than 2 chars, without calling',
      (tester) async {
        repo = RepoLugarFalso(alBuscar: (_) => resultado([_kennedy]));
        await abrir(tester);
        expect(find.text(_hint), findsOneWidget);

        await escribir(tester, 'P');
        await tester.pump(const Duration(seconds: 1));

        expect(find.text(_hint), findsOneWidget);
        expect(repo.pedidos, isEmpty);
      },
    );
  });

  group('results', () {
    testWidgets('lists the matches with count, distance and level', (
      tester,
    ) async {
      repo = RepoLugarFalso(
        alBuscar: (_) => resultado([_kennedy, _exposicion]),
      );
      await abrir(tester);

      await escribir(tester, 'Parque');

      expect(repo.pedidos.single.q, 'Parque');
      expect(find.text('2 RESULTADOS'), findsOneWidget);
      expect(find.text('Parque Kennedy'), findsOneWidget);
      expect(find.text('Parque de la Exposición'), findsOneWidget);
      expect(find.text('Parque · 315 m'), findsOneWidget);
      expect(find.text('Parque · 6.0 km'), findsOneWidget);
      expect(find.text('Moderado'), findsOneWidget);
      expect(find.text('Tranquilo'), findsOneWidget);
      expect(find.text(_hint), findsNothing);
    });

    testWidgets('one match is singular', (tester) async {
      repo = RepoLugarFalso(alBuscar: (_) => resultado([_kennedy]));
      await abrir(tester);

      await escribir(tester, 'Kennedy');

      expect(find.text('1 RESULTADO'), findsOneWidget);
    });

    testWidgets('without a known map centre only the category is shown', (
      tester,
    ) async {
      repo = RepoLugarFalso(alBuscar: (_) => resultado([_kennedy]));
      await abrir(tester, centro: null);

      await escribir(tester, 'Kennedy');

      expect(find.text('Parque'), findsOneWidget);
      expect(find.textContaining('Parque ·'), findsNothing);
    });

    testWidgets('tapping a result returns its id to the caller', (
      tester,
    ) async {
      repo = RepoLugarFalso(
        alBuscar: (_) => resultado([_kennedy, _exposicion]),
      );
      await abrir(tester);
      await escribir(tester, 'Parque');

      await tester.tap(find.text('Parque de la Exposición'));
      await tester.pumpAndSettle();

      expect(elegido, 4);
      expect(find.byType(BuscarLugarPage), findsNothing);
    });
  });

  group('empty and error', () {
    testWidgets('no match shows the HU 3.4 empty state for the query', (
      tester,
    ) async {
      repo = RepoLugarFalso(alBuscar: (_) => resultado([]));
      await abrir(tester);

      await escribir(tester, 'Zoológico');

      expect(find.text('SIN RESULTADOS'), findsOneWidget);
      expect(find.text('Sin resultados'), findsOneWidget);
      expect(
        find.text(
          'No encontramos lugares para “Zoológico”. Prueba con otro nombre.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a failure shows the message and Reintentar searches again', (
      tester,
    ) async {
      var falla = true;
      repo = RepoLugarFalso(
        alBuscar: (_) async {
          if (falla) throw const ApiException.sinConexion();
          return (await resultado([_kennedy]));
        },
      );
      await abrir(tester);
      await escribir(tester, 'Par');

      expect(
        find.text(
          'No pudimos realizar la búsqueda. Revisa tu conexión e inténtalo de nuevo.',
        ),
        findsOneWidget,
      );

      falla = false;
      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Parque Kennedy'), findsOneWidget);
      expect(repo.pedidos.map((p) => p.q), ['Par', 'Par']);
    });
  });
}
