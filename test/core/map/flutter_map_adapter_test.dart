import 'dart:convert';

import 'package:crowdradar/core/map/flutter_map_adapter.dart';
import 'package:crowdradar/core/map/mapa_adapter.dart';
import 'package:crowdradar/core/map/tipos_mapa.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/widgets/pin_saturacion.dart';
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
            alMoverCamara: (l) => limites = l,
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
}
