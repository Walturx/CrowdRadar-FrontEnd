import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../widgets/pin_saturacion.dart';
import 'mapa_adapter.dart';
import 'tipos_mapa.dart';

/// Adapter pattern: implements the [MapaAdapter] port with OpenStreetMap tiles
/// through `flutter_map`; the only file allowed to import it.
class FlutterMapAdapter implements MapaAdapter {
  static const String urlTiles =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String userAgent = 'com.crowdradar.app';
  /// TextSourceAttribution prepends the copyright sign itself.
  static const String atribucion = 'OpenStreetMap contributors';
  static const double zoomPorDefecto = 13;
  static const double _tamanoMarcador = 40;

  /// Injectable so tests never hit the network.
  final TileProvider? _tileProvider;

  FlutterMapAdapter({TileProvider? tileProvider})
    : _tileProvider = tileProvider;

  @override
  Widget construirMapa({
    required PuntoGeografico centro,
    double zoom = zoomPorDefecto,
    List<MarcadorLugar> marcadores = const [],
    required void Function(int lugarId) alTocarMarcador,
    void Function(LimitesMapa limites)? alMoverCamara,
    PuntoGeografico? ubicacionUsuario,
  }) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(centro.latitud, centro.longitud),
        initialZoom: zoom,
        onPositionChanged: alMoverCamara == null
            ? null
            : (camara, _) {
                final b = camara.visibleBounds;
                alMoverCamara(
                  LimitesMapa(
                    norte: b.north,
                    sur: b.south,
                    este: b.east,
                    oeste: b.west,
                  ),
                );
              },
      ),
      children: [
        TileLayer(
          urlTemplate: urlTiles,
          userAgentPackageName: userAgent,
          tileProvider: _tileProvider,
        ),
        MarkerLayer(
          markers: [
            for (final m in marcadores)
              Marker(
                point: LatLng(m.latitud, m.longitud),
                width: _tamanoMarcador,
                height: _tamanoMarcador,
                child: PinSaturacion(
                  key: ValueKey('marcador-${m.lugarId}'),
                  nivel: m.nivel,
                  etiqueta: m.etiqueta,
                  onTap: () => alTocarMarcador(m.lugarId),
                ),
              ),
            if (ubicacionUsuario != null)
              Marker(
                point: LatLng(
                  ubicacionUsuario.latitud,
                  ubicacionUsuario.longitud,
                ),
                width: 20,
                height: 20,
                child: const Icon(
                  Icons.circle,
                  key: ValueKey('ubicacion-usuario'),
                  color: Colors.blue,
                  size: 20,
                ),
              ),
          ],
        ),
        const RichAttributionWidget(
          attributions: [TextSourceAttribution(atribucion)],
        ),
      ],
    );
  }
}
