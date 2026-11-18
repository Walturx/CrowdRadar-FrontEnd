import 'package:crowdradar/app/rutas.dart';
import 'package:crowdradar/core/map/mapa_adapter.dart';
import 'package:crowdradar/core/map/tipos_mapa.dart';
import 'package:crowdradar/core/models/categoria_lugar.dart';
import 'package:crowdradar/core/models/lugar_resumen.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/widgets/pin_saturacion.dart';
import 'package:crowdradar/features/exploracion/data/exploracion_repository.dart';
import 'package:crowdradar/features/lugares/data/lugar_repository.dart';
import 'package:crowdradar/features/lugares/mapa/map_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/enrutador_falso.dart';
import '../fakes/exploracion_repository_fake.dart';
import '../fakes/lugar_repo_falso.dart';
import 'golden_harness.dart';

/// One place per level, so every pin color is in the image.
const _places = [
  LugarResumen(
    id: 1,
    nombre: 'Parque Kennedy',
    categoria: CategoriaLugar.parque,
    latitud: -12.1219,
    longitud: -77.0297,
    saturacion: NivelSaturacion.tranquilo,
  ),
  LugarResumen(
    id: 2,
    nombre: 'Mercado de Surquillo',
    categoria: CategoriaLugar.mercado,
    latitud: -12.1114,
    longitud: -77.0156,
    saturacion: NivelSaturacion.moderado,
  ),
  LugarResumen(
    id: 3,
    nombre: 'Larcomar',
    categoria: CategoriaLugar.centroComercial,
    latitud: -12.1318,
    longitud: -77.0304,
    saturacion: NivelSaturacion.saturado,
  ),
  LugarResumen(
    id: 4,
    nombre: 'Plaza de Armas',
    categoria: CategoriaLugar.plaza,
    latitud: -12.0464,
    longitud: -77.0300,
    saturacion: NivelSaturacion.sinInformacion,
  ),
];

const _bbox = LimitesMapa(
  norte: -12.10,
  sur: -12.14,
  este: -77.00,
  oeste: -77.06,
);

/// Map port double that never loads tiles: a flat background with the real
/// pins at fixed spots, so the image only shows what the app draws on top.
class _FlatMap implements MapaAdapter {
  EventosMapa events = const EventosMapa();

  static const List<Offset> _spots = [
    Offset(60, 90),
    Offset(250, 140),
    Offset(120, 300),
    Offset(280, 380),
  ];

  @override
  Widget construirMapa({
    required PuntoGeografico centro,
    double zoom = 13,
    List<MarcadorLugar> marcadores = const [],
    required void Function(int lugarId) alTocarMarcador,
    EventosMapa eventos = const EventosMapa(),
    PuntoGeografico? ubicacionUsuario,
  }) {
    events = eventos;
    return ColoredBox(
      color: const Color(0xFFE8EAED),
      child: Stack(
        children: [
          for (final (i, m) in marcadores.indexed)
            Positioned(
              left: _spots[i % _spots.length].dx,
              top: _spots[i % _spots.length].dy,
              child: PinSaturacion(
                nivel: m.nivel,
                onTap: () => alTocarMarcador(m.lugarId),
              ),
            ),
        ],
      ),
    );
  }
}

void main() {
  testWidgets('map, loaded with a pin of every level', (tester) async {
    usePhoneSurface(tester);
    final map = _FlatMap();
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<MapaAdapter>.value(value: map),
          RepositoryProvider<LugarRepository>.value(
            value: RepoLugarFalso(alBuscar: (_) => resultado(_places)),
          ),
          RepositoryProvider<ExploracionRepository>.value(
            value: ExploracionRepositoryFake(),
          ),
        ],
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: appTheme,
          builder: withoutAnimations,
          routerConfig: enrutadorDe(
            ruta: Rutas.mapa,
            inicial: Rutas.mapa,
            pantalla: const MapPage(),
          ),
        ),
      ),
    );
    await tester.pump();
    map.events.alCamaraQuieta!(_bbox);
    await tester.pumpAndSettle();

    expect(find.byType(PinSaturacion), findsNWidgets(_places.length));
    await matchBaseline('mapa_cargado');
  });
}
