import 'package:crowdradar/app/fakes/exploracion_repository_fake.dart';
import 'package:crowdradar/app/rutas.dart';
import 'package:crowdradar/core/map/mapa_adapter.dart';
import 'package:crowdradar/core/map/tipos_mapa.dart';
import 'package:crowdradar/core/models/categoria_lugar.dart';
import 'package:crowdradar/core/models/lugar_resumen.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/widgets/pin_saturacion.dart';
import 'package:crowdradar/features/exploracion/data/exploracion_repository.dart';
import 'package:crowdradar/features/lugares/buscar/buscar_lugar_page.dart';
import 'package:crowdradar/features/lugares/data/lugar_repository.dart';
import 'package:crowdradar/features/lugares/mapa/leyenda_saturacion.dart';
import 'package:crowdradar/features/lugares/mapa/map_page.dart';
import 'package:crowdradar/features/lugares/mapa/marcadores.dart';
import 'package:crowdradar/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../fakes/lugar_repo_falso.dart';

const _kennedy = LugarResumen(
  id: 1,
  nombre: 'Parque Kennedy',
  categoria: CategoriaLugar.parque,
  latitud: -12.1219,
  longitud: -77.0297,
  saturacion: NivelSaturacion.moderado,
);
const _mercado = LugarResumen(
  id: 2,
  nombre: 'Mercado de Surquillo',
  categoria: CategoriaLugar.mercado,
  latitud: -12.1114,
  longitud: -77.0156,
  saturacion: NivelSaturacion.sinInformacion,
);
const _bbox = LimitesMapa(
  norte: -12.10,
  sur: -12.14,
  este: -77.00,
  oeste: -77.06,
);

/// Map port double: draws one pin per marker and lets tests fire its callbacks.
class _MapaFalso implements MapaAdapter {
  List<MarcadorLugar> marcadores = const [];
  late void Function(int) alTocar;
  EventosMapa eventos = const EventosMapa();
  void Function(LimitesMapa) get alCamaraQuieta => eventos.alCamaraQuieta!;
  void Function(LimitesMapa) get alMoverCamara => eventos.alMoverCamara!;
  VoidCallback get alErrorTile => eventos.alErrorTile!;
  VoidCallback get alTileCargado => eventos.alTileCargado!;

  @override
  Widget construirMapa({
    required PuntoGeografico centro,
    double zoom = 13,
    List<MarcadorLugar> marcadores = const [],
    required void Function(int lugarId) alTocarMarcador,
    EventosMapa eventos = const EventosMapa(),
    PuntoGeografico? ubicacionUsuario,
  }) {
    this.marcadores = marcadores;
    alTocar = alTocarMarcador;
    this.eventos = eventos;
    return Column(
      key: const ValueKey('mapa-falso'),
      children: [
        for (final m in marcadores)
          PinSaturacion(
            key: ValueKey('pin-${m.lugarId}'),
            nivel: m.nivel,
            onTap: () => alTocarMarcador(m.lugarId),
          ),
      ],
    );
  }
}

void main() {
  late _MapaFalso mapa;
  late RepoLugarFalso repo;
  Object? extraDetalle;

  Future<void> abrir(WidgetTester tester) async {
    mapa = _MapaFalso();
    extraDetalle = null;
    final router = GoRouter(
      initialLocation: Rutas.mapa,
      routes: [
        GoRoute(path: Rutas.mapa, builder: (_, _) => const MapPage()),
        GoRoute(
          path: Rutas.buscarLugar,
          builder: (_, s) => BuscarLugarPage(
            centroMapa: s.extra is PuntoGeografico
                ? s.extra as PuntoGeografico
                : null,
          ),
        ),
        GoRoute(
          path: Rutas.lugarPlantilla,
          builder: (_, s) {
            extraDetalle = s.extra;
            return Scaffold(body: Text('DETALLE ${s.pathParameters['id']}'));
          },
        ),
      ],
    );
    await tester.pumpWidget(
      RepositoryProvider<MapaAdapter>.value(
        value: mapa,
        child: RepositoryProvider<LugarRepository>.value(
          value: repo,
          child: RepositoryProvider<ExploracionRepository>.value(
            value: ExploracionRepositoryFake(),
            child: MaterialApp.router(routerConfig: router),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> alCamaraQuieta(
    WidgetTester tester, [
    LimitesMapa b = _bbox,
  ]) async {
    mapa.alCamaraQuieta(b);
    await tester.pump();
    await tester.pump();
  }

  Color? colorDelPin(WidgetTester tester, int id) => tester
      .widget<Icon>(
        find.descendant(
          of: find.byKey(ValueKey('pin-$id')),
          matching: find.byType(Icon),
        ),
      )
      .color;

  group('markers', () {
    test('marcadoresDe keeps the place coordinates, level and name', () {
      expect(marcadoresDe(const [_kennedy, _mercado]), const [
        MarcadorLugar(
          lugarId: 1,
          latitud: -12.1219,
          longitud: -77.0297,
          nivel: NivelSaturacion.moderado,
          etiqueta: 'Parque Kennedy',
        ),
        MarcadorLugar(
          lugarId: 2,
          latitud: -12.1114,
          longitud: -77.0156,
          nivel: NivelSaturacion.sinInformacion,
          etiqueta: 'Mercado de Surquillo',
        ),
      ]);
      expect(marcadoresDe(const []), isEmpty);
    });

    testWidgets(
      'one pin per place, colored by level, grey without information',
      (tester) async {
        repo = RepoLugarFalso(alBuscar: (_) => resultado([_kennedy, _mercado]));
        await abrir(tester);
        await alCamaraQuieta(tester);

        expect(find.byType(PinSaturacion), findsNWidgets(2));
        expect(mapa.marcadores.map((m) => m.lugarId), [1, 2]);
        expect(colorDelPin(tester, 1), AppColors.warning);
        expect(colorDelPin(tester, 2), AppColors.textMuted);
      },
    );

    testWidgets('the first camera report loads that bbox at once', (
      tester,
    ) async {
      repo = RepoLugarFalso(alBuscar: (_) => resultado([_kennedy]));
      await abrir(tester);
      await alCamaraQuieta(tester);

      expect(repo.pedidos.map((p) => p.bbox), [_bbox]);
      expect(repo.pedidos.single.q, isNull);
    });

    testWidgets('later camera reports are debounced', (tester) async {
      repo = RepoLugarFalso(alBuscar: (_) => resultado([_kennedy]));
      await abrir(tester);
      await alCamaraQuieta(tester);
      const otro = LimitesMapa(
        norte: -12.0,
        sur: -12.04,
        este: -77.0,
        oeste: -77.06,
      );

      mapa.alCamaraQuieta(otro);
      await tester.pump(const Duration(milliseconds: 300));
      expect(repo.pedidos, hasLength(1));

      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
      expect(repo.pedidos.map((p) => p.bbox), [_bbox, otro]);
    });
  });

  group('filters (HU 3.5, 3.6)', () {
    testWidgets('a category chip reloads the markers with that category', (
      tester,
    ) async {
      repo = RepoLugarFalso(
        alBuscar: (p) => resultado(
          p.categoria == CategoriaLugar.mercado ? [_mercado] : [_kennedy, _mercado],
        ),
      );
      await abrir(tester);
      await alCamaraQuieta(tester);
      expect(find.byType(PinSaturacion), findsNWidgets(2));

      await tester.tap(find.text('Mercados'));
      await tester.pump();
      await tester.pump();

      expect(repo.pedidos.last.categoria, CategoriaLugar.mercado);
      expect(repo.pedidos.last.bbox, _bbox);
      expect(mapa.marcadores.map((m) => m.lugarId), [2]);
      expect(find.byType(PinSaturacion), findsOneWidget);
    });

    testWidgets('choosing another category replaces the previous filter', (
      tester,
    ) async {
      repo = RepoLugarFalso(alBuscar: (_) => resultado([_kennedy]));
      await abrir(tester);
      await alCamaraQuieta(tester);

      await tester.tap(find.text('Mercados'));
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('Parques'));
      await tester.pump();
      await tester.pump();

      expect(repo.pedidos.last.categoria, CategoriaLugar.parque);
    });

    testWidgets('the level control filters and combines with the category', (
      tester,
    ) async {
      repo = RepoLugarFalso(alBuscar: (_) => resultado([_kennedy]));
      await abrir(tester);
      await alCamaraQuieta(tester);

      await tester.tap(find.byKey(const Key('nivel-saturado')));
      await tester.pump();
      await tester.pump();

      expect(repo.pedidos.last.nivel, NivelSaturacion.saturado);
      expect(repo.pedidos.last.categoria, isNull);
    });

    testWidgets('no result explains it with the category message', (
      tester,
    ) async {
      repo = RepoLugarFalso(
        alBuscar: (p) => resultado(p.categoria == null ? [_kennedy] : const []),
      );
      await abrir(tester);
      await alCamaraQuieta(tester);

      await tester.tap(find.text('Mercados'));
      await tester.pump();
      await tester.pump();

      expect(
        find.text('No hay lugares cercanos disponibles para esa categoría.'),
        findsOneWidget,
      );
      expect(find.byType(PinSaturacion), findsNothing);
    });

    testWidgets('moving the map keeps the filter', (tester) async {
      repo = RepoLugarFalso(alBuscar: (_) => resultado([_kennedy]));
      await abrir(tester);
      await alCamaraQuieta(tester);
      await tester.tap(find.text('Parques'));
      await tester.pump();
      await tester.pump();
      const otro = LimitesMapa(
        norte: -12.0,
        sur: -12.04,
        este: -77.0,
        oeste: -77.06,
      );

      mapa.alCamaraQuieta(otro);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();

      expect(repo.pedidos.last.bbox, otro);
      expect(repo.pedidos.last.categoria, CategoriaLugar.parque);
    });
  });

  group('states', () {
    testWidgets('an empty zone shows the server message, not an error', (
      tester,
    ) async {
      repo = RepoLugarFalso(
        alBuscar: (_) =>
            resultado(const [], mensaje: 'No hay lugares en esta zona.'),
      );
      await abrir(tester);
      await alCamaraQuieta(tester);

      expect(find.text('No hay lugares en esta zona.'), findsOneWidget);
      expect(find.byType(PinSaturacion), findsNothing);
      expect(find.text('Reintentar'), findsNothing);
    });

    testWidgets('an error shows the HU 3.1 message and Reintentar reloads', (
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
      await alCamaraQuieta(tester);

      expect(find.text('No pudimos cargar el mapa'), findsOneWidget);
      expect(
        find.text(
          'Hubo un error al obtener la información geográfica. Revisa tu conexión e inténtalo de nuevo.',
        ),
        findsOneWidget,
      );

      falla = false;
      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      await tester.pump();

      expect(find.text('No pudimos cargar el mapa'), findsNothing);
      expect(find.byType(PinSaturacion), findsOneWidget);
      expect(repo.pedidos.map((p) => p.bbox), [_bbox, _bbox]);
    });

    testWidgets('a non-connection failure gets the generic message', (
      tester,
    ) async {
      repo = RepoLugarFalso(
        alBuscar: (_) async => throw const ApiException(
          status: 500,
          message: 'boom',
          code: 'ERROR_INTERNO',
        ),
      );
      await abrir(tester);
      await alCamaraQuieta(tester);

      expect(find.text('No pudimos cargar los lugares'), findsOneWidget);
      expect(find.textContaining('Revisa tu conexión'), findsNothing);
    });

    testWidgets('the error is a dismissible card that does not cover the map', (
      tester,
    ) async {
      repo = RepoLugarFalso(
        alBuscar: (_) async => throw const ApiException.sinConexion(),
      );
      await abrir(tester);
      await alCamaraQuieta(tester);

      final tarjeta = tester.getRect(
        find.byKey(const ValueKey('tarjeta-error')),
      );
      final mapaRect = tester.getRect(find.byKey(const ValueKey('mapa-falso')));
      expect(find.byKey(const ValueKey('mapa-falso')), findsOneWidget);
      expect(tarjeta.height, lessThan(mapaRect.height));

      await tester.tap(find.byKey(const ValueKey('cerrar-error')));
      await tester.pump();

      expect(find.byKey(const ValueKey('tarjeta-error')), findsNothing);
    });

    testWidgets('the legend names the three levels', (tester) async {
      repo = RepoLugarFalso();
      await abrir(tester);

      final leyenda = find.byType(LeyendaSaturacion);
      for (final nivel in ['Tranquilo', 'Moderado', 'Saturado']) {
        expect(
          find.descendant(of: leyenda, matching: find.text(nivel)),
          findsOneWidget,
        );
      }
    });
  });

  group('navigation', () {
    testWidgets('tapping a marker opens that place with the map centre', (
      tester,
    ) async {
      repo = RepoLugarFalso(alBuscar: (_) => resultado([_kennedy, _mercado]));
      await abrir(tester);
      await alCamaraQuieta(tester);

      await tester.tap(find.byKey(const ValueKey('pin-2')));
      await tester.pumpAndSettle();

      expect(find.text('DETALLE 2'), findsOneWidget);
      final centro = extraDetalle as PuntoGeografico;
      expect(centro.latitud, closeTo(-12.12, 1e-9));
      expect(centro.longitud, closeTo(-77.03, 1e-9));
    });
  });

  group('live centre', () {
    testWidgets('a tap during a pending debounce uses the live camera centre', (
      tester,
    ) async {
      repo = RepoLugarFalso(alBuscar: (_) => resultado([_kennedy, _mercado]));
      await abrir(tester);
      await alCamaraQuieta(tester);
      const otro = LimitesMapa(
        norte: -12.0,
        sur: -12.04,
        este: -77.0,
        oeste: -77.06,
      );

      mapa.alMoverCamara(otro);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const ValueKey('pin-1')));
      await tester.pumpAndSettle();

      final centro = extraDetalle as PuntoGeografico;
      expect(centro.latitud, closeTo(-12.02, 1e-9));
      expect(centro.longitud, closeTo(-77.03, 1e-9));
    });
  });

  group('search hook', () {
    testWidgets(
      'the search field opens the search and a chosen place opens its detail',
      (tester) async {
        repo = RepoLugarFalso(
          alBuscar: (p) => resultado(p.q == null ? [_kennedy] : [_mercado]),
        );
        await abrir(tester);
        await alCamaraQuieta(tester);

        await tester.tap(find.text('Buscar lugares'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Merc');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();
        expect(repo.pedidos.last.q, 'Merc');
        expect(repo.pedidos.last.bbox, isNull);

        await tester.tap(find.text('Mercado de Surquillo'));
        await tester.pumpAndSettle();

        expect(find.text('DETALLE 2'), findsOneWidget);
        expect(extraDetalle, isA<PuntoGeografico>());
      },
    );

    testWidgets('going back from the search without choosing keeps the map', (
      tester,
    ) async {
      repo = RepoLugarFalso(alBuscar: (_) => resultado([_kennedy]));
      await abrir(tester);
      await alCamaraQuieta(tester);

      await tester.tap(find.text('Buscar lugares'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(PinSaturacion), findsOneWidget);
      expect(find.textContaining('DETALLE'), findsNothing);
    });
  });

  group('tile errors (R4-104)', () {
    testWidgets('the first tile error shows the banner and keeps the markers', (
      tester,
    ) async {
      repo = RepoLugarFalso(alBuscar: (_) => resultado([_kennedy]));
      await abrir(tester);
      await alCamaraQuieta(tester);
      expect(find.text('Sin conexión al mapa'), findsNothing);

      mapa.alErrorTile();
      await tester.pump();

      expect(find.text('Sin conexión al mapa'), findsOneWidget);
      expect(find.byType(PinSaturacion), findsOneWidget);
    });

    testWidgets('once dismissed it is not shown again in the session', (
      tester,
    ) async {
      repo = RepoLugarFalso(alBuscar: (_) => resultado([_kennedy]));
      await abrir(tester);
      await alCamaraQuieta(tester);

      mapa.alErrorTile();
      mapa.alErrorTile();
      await tester.pump();
      expect(find.text('Sin conexión al mapa'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(find.text('Sin conexión al mapa'), findsNothing);

      mapa.alErrorTile();
      await tester.pump();
      expect(find.text('Sin conexión al mapa'), findsNothing);
    });

    testWidgets('a tile that loads again clears the banner and re-arms it', (
      tester,
    ) async {
      repo = RepoLugarFalso(alBuscar: (_) => resultado([_kennedy]));
      await abrir(tester);
      await alCamaraQuieta(tester);

      mapa.alErrorTile();
      await tester.pump();
      expect(find.text('Sin conexión al mapa'), findsOneWidget);

      mapa.alTileCargado();
      await tester.pump();
      expect(find.text('Sin conexión al mapa'), findsNothing);

      mapa.alErrorTile();
      await tester.pump();
      expect(find.text('Sin conexión al mapa'), findsOneWidget);
    });

    testWidgets('a dismissed banner returns after recovery and a new outage', (
      tester,
    ) async {
      repo = RepoLugarFalso(alBuscar: (_) => resultado([_kennedy]));
      await abrir(tester);
      await alCamaraQuieta(tester);

      mapa.alErrorTile();
      await tester.pump();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      mapa.alErrorTile();
      await tester.pump();
      expect(find.text('Sin conexión al mapa'), findsNothing);

      mapa.alTileCargado();
      mapa.alErrorTile();
      await tester.pump();

      expect(find.text('Sin conexión al mapa'), findsOneWidget);
    });
  });
}
