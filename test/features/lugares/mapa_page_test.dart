import 'package:crowdradar/app/rutas.dart';
import 'package:crowdradar/core/map/mapa_adapter.dart';
import 'package:crowdradar/core/map/tipos_mapa.dart';
import 'package:crowdradar/core/models/categoria_lugar.dart';
import 'package:crowdradar/core/models/lugar_resumen.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/widgets/pin_saturacion.dart';
import 'package:crowdradar/features/lugares/data/lugar_repository.dart';
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
  void Function(LimitesMapa)? alCamaraQuieta;
  VoidCallback? alErrorTile;

  @override
  Widget construirMapa({
    required PuntoGeografico centro,
    double zoom = 13,
    List<MarcadorLugar> marcadores = const [],
    required void Function(int lugarId) alTocarMarcador,
    void Function(LimitesMapa limites)? alMoverCamara,
    void Function(LimitesMapa limites)? alCamaraQuieta,
    VoidCallback? alErrorTile,
    PuntoGeografico? ubicacionUsuario,
  }) {
    this.marcadores = marcadores;
    alTocar = alTocarMarcador;
    this.alCamaraQuieta = alCamaraQuieta;
    this.alErrorTile = alErrorTile;
    return Column(
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
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> alCamaraQuieta(
    WidgetTester tester, [
    LimitesMapa b = _bbox,
  ]) async {
    mapa.alCamaraQuieta!(b);
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

      mapa.alCamaraQuieta!(otro);
      await tester.pump(const Duration(milliseconds: 300));
      expect(repo.pedidos, hasLength(1));

      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
      expect(repo.pedidos.map((p) => p.bbox), [_bbox, otro]);
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

    testWidgets('the legend names the three levels', (tester) async {
      repo = RepoLugarFalso();
      await abrir(tester);

      expect(find.text('Tranquilo'), findsOneWidget);
      expect(find.text('Moderado'), findsOneWidget);
      expect(find.text('Saturado'), findsOneWidget);
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

      mapa.alErrorTile!();
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

      mapa.alErrorTile!();
      mapa.alErrorTile!();
      await tester.pump();
      expect(find.text('Sin conexión al mapa'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(find.text('Sin conexión al mapa'), findsNothing);

      mapa.alErrorTile!();
      await tester.pump();
      expect(find.text('Sin conexión al mapa'), findsNothing);
    });
  });
}
