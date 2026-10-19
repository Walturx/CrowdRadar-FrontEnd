import 'dart:convert';

import 'package:crowdradar/core/map/flutter_map_adapter.dart';
import 'package:crowdradar/core/map/mapa_adapter.dart';
import 'package:crowdradar/core/map/tipos_mapa.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/widgets/pin_saturacion.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

/// 1x1 transparent PNG so tests never hit the network.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

class _TileProviderLocal extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(_png);
}

/// Every tile fails to load, like a device without connection.
class _ImagenFallida extends ImageProvider<_ImagenFallida> {
  @override
  Future<_ImagenFallida> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _ImagenFallida key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(Future.error(Exception('sin red')));
}

class _TileProviderFallido extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      _ImagenFallida();
}

const _centro = PuntoGeografico(-12.0464, -77.0428);

const _marcadores = [
  MarcadorLugar(
    lugarId: 1,
    latitud: -12.0464,
    longitud: -77.0428,
    nivel: NivelSaturacion.tranquilo,
    etiqueta: 'Plaza',
  ),
  MarcadorLugar(
    lugarId: 2,
    latitud: -12.0470,
    longitud: -77.0420,
    nivel: NivelSaturacion.saturado,
    etiqueta: 'Mercado',
  ),
  MarcadorLugar(
    lugarId: 3,
    latitud: -12.0458,
    longitud: -77.0436,
    nivel: NivelSaturacion.sinInformacion,
    etiqueta: 'Parque',
  ),
];

Future<void> _montar(
  WidgetTester tester,
  MapaAdapter adapter, {
  List<MarcadorLugar> marcadores = _marcadores,
  void Function(int)? alTocar,
  PuntoGeografico? ubicacionUsuario,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: adapter.construirMapa(
        centro: _centro,
        zoom: 16,
        marcadores: marcadores,
        alTocarMarcador: alTocar ?? (_) {},
        ubicacionUsuario: ubicacionUsuario,
      ),
    ),
  ),
);

void main() {
  final adapter = FlutterMapAdapter(tileProvider: _TileProviderLocal());

  testWidgets('S7.1 renders one pin per marker', (tester) async {
    await _montar(tester, adapter);

    expect(find.byType(PinSaturacion), findsNWidgets(3));
  });

  testWidgets('S7.1 renders a different count for a different input', (
    tester,
  ) async {
    await _montar(tester, adapter, marcadores: _marcadores.take(1).toList());

    expect(find.byType(PinSaturacion), findsOneWidget);

    await _montar(tester, adapter, marcadores: const []);
    expect(find.byType(PinSaturacion), findsNothing);
  });

  testWidgets('S7.1 shows the OpenStreetMap attribution', (tester) async {
    await _montar(tester, adapter);

    await tester.tap(find.byIcon(Icons.info_outlined));
    await tester.pump();

    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
  });

  testWidgets('S7.1 tapping a marker reports its lugarId', (tester) async {
    final tocados = <int>[];
    await _montar(tester, adapter, alTocar: tocados.add);

    await tester.tap(find.byKey(const ValueKey('marcador-2')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('marcador-1')));
    await tester.pump();

    expect(tocados, [2, 1]);
  });

  testWidgets('user location adds its own marker', (tester) async {
    await _montar(tester, adapter, ubicacionUsuario: _centro);

    expect(find.byKey(const ValueKey('ubicacion-usuario')), findsOneWidget);
  });

  testWidgets('camera movement reports the visible bounds', (tester) async {
    LimitesMapa? limites;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: adapter.construirMapa(
            centro: _centro,
            zoom: 16,
            alTocarMarcador: (_) {},
            eventos: EventosMapa(alMoverCamara: (l) => limites = l),
          ),
        ),
      ),
    );

    await tester.drag(find.byType(FlutterMap), const Offset(-120, 0));
    await tester.pump();

    expect(limites, isNotNull);
    expect(limites!.norte, greaterThan(limites!.sur));
    expect(limites!.este, greaterThan(limites!.oeste));
  });

  group('camera idle', () {
    Future<void> montar(
      WidgetTester tester,
      void Function(LimitesMapa) alCamaraQuieta,
    ) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: adapter.construirMapa(
            centro: _centro,
            zoom: 16,
            alTocarMarcador: (_) {},
            eventos: EventosMapa(alCamaraQuieta: alCamaraQuieta),
          ),
        ),
      ),
    );

    testWidgets('reports the initial bounds once the map is ready', (
      tester,
    ) async {
      final reportes = <LimitesMapa>[];
      await montar(tester, reportes.add);
      await tester.pump();

      expect(reportes, hasLength(1));
      expect(reportes.single.norte, greaterThan(_centro.latitud));
      expect(reportes.single.sur, lessThan(_centro.latitud));
      expect(reportes.single.este, greaterThan(_centro.longitud));
      expect(reportes.single.oeste, lessThan(_centro.longitud));
    });

    testWidgets('reports new bounds when a drag ends, not before', (
      tester,
    ) async {
      final reportes = <LimitesMapa>[];
      await montar(tester, reportes.add);
      await tester.pump();
      final inicial = reportes.single;

      final gesto = await tester.startGesture(
        tester.getCenter(find.byType(FlutterMap)),
      );
      await gesto.moveBy(const Offset(-120, 0));
      await tester.pump();
      expect(reportes, hasLength(1));

      await gesto.up();
      await tester.pumpAndSettle();

      expect(reportes.length, greaterThan(1));
      expect(reportes.last.oeste, isNot(inicial.oeste));
      expect(reportes.last.este, greaterThan(inicial.este));
    });
  });

  group('tile errors', () {
    Future<void> montar(
      WidgetTester tester,
      TileProvider tiles,
      VoidCallback alError, [
      VoidCallback? alCargado,
    ]) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlutterMapAdapter(tileProvider: tiles).construirMapa(
            centro: _centro,
            zoom: 16,
            alTocarMarcador: (_) {},
            eventos: EventosMapa(
              alErrorTile: alError,
              alTileCargado: alCargado,
            ),
          ),
        ),
      ),
    );

    testWidgets('a tile that fails to load is reported', (tester) async {
      var errores = 0;
      await montar(tester, _TileProviderFallido(), () => errores++);
      await tester.pump();
      await tester.pump();

      expect(errores, greaterThan(0));
    });

    testWidgets('tiles that load do not report errors', (tester) async {
      var errores = 0;
      await montar(tester, _TileProviderLocal(), () => errores++);
      await tester.pump();
      await tester.pump();

      expect(find.byType(TileLayer), findsOneWidget);
      expect(errores, 0);
    });

    testWidgets('tiles that load are reported as loaded', (tester) async {
      var cargados = 0;
      await montar(tester, _TileProviderLocal(), () {}, () => cargados++);
      await tester.pump();
      await tester.pump();

      expect(cargados, greaterThan(0));
    });

    testWidgets('tiles that fail are not reported as loaded', (tester) async {
      var cargados = 0;
      await montar(tester, _TileProviderFallido(), () {}, () => cargados++);
      await tester.pump();
      await tester.pump();

      expect(cargados, 0);
    });
  });

  group('disk tile cache', () {
    test('by default tiles go through the network with the disk cache', () {
      const cache = _CacheFalso();
      final proveedor = FlutterMapAdapter(
        cacheTiles: () => cache,
      ).proveedorTiles();

      expect(proveedor, isA<NetworkTileProvider>());
      expect((proveedor as NetworkTileProvider).cachingProvider, same(cache));
    });

    test('an injected tile provider wins over the cache', () {
      final local = _TileProviderLocal();

      expect(
        FlutterMapAdapter(
          tileProvider: local,
          cacheTiles: () => throw StateError('must not be created'),
        ).proveedorTiles(),
        same(local),
      );
    });

    test('the cache keeps at most 200 MB of tiles', () {
      expect(FlutterMapAdapter.tamanoMaximoCache, 200 * 1024 * 1024);
    });

    testWidgets('requests identify the app per the OSM tile policy', (
      tester,
    ) async {
      await _montar(tester, adapter);

      final capa = tester.widget<TileLayer>(find.byType(TileLayer));
      expect(
        capa.tileProvider.headers['User-Agent'],
        'flutter_map (${FlutterMapAdapter.userAgent})',
      );
      expect(FlutterMapAdapter.userAgent, 'com.example.crowdradar');
    });
  });
}

class _CacheFalso with DisabledMapCachingProvider {
  const _CacheFalso();
}
