import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../network/cliente_http_factory.dart';
import '../widgets/pin_saturacion.dart';
import 'mapa_adapter.dart';
import 'tipos_mapa.dart';

/// Adapter pattern: implements the [MapaAdapter] port with OpenStreetMap tiles
/// through `flutter_map`; the only file allowed to import it.
class FlutterMapAdapter implements MapaAdapter {
  static const String urlTiles =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// OSM tile usage policy: identify the app (its Android applicationId).
  static const String userAgent = 'com.example.crowdradar';

  /// TextSourceAttribution prepends the copyright sign itself.
  static const String atribucion = 'OpenStreetMap contributors';
  static const double zoomPorDefecto = 13;
  static const double _tamanoMarcador = 40;
  static const double _tamanoUbicacion = 20;
  static const Color _colorUbicacion = Colors.blue;

  /// Upper bound of the on-disk tile cache.
  static const int tamanoMaximoCache = 200 * 1024 * 1024;

  /// Injectable so tests never hit the network.
  final TileProvider? _tileProvider;

  /// Created on the first real map only (it touches the file system).
  final MapCachingProvider Function() _cacheTiles;

  /// Shared by every map: the layer disposes its provider, never this client.
  late final _clienteTiles = const ClienteHttpFactory().crear();

  FlutterMapAdapter({
    TileProvider? tileProvider,
    MapCachingProvider Function()? cacheTiles,
  }) : _tileProvider = tileProvider,
       _cacheTiles = cacheTiles ?? _cacheEnDisco;

  /// flutter_map's built-in disk cache, which honours the tile server's
  /// HTTP freshness headers (OSM policy) and survives app restarts.
  static MapCachingProvider _cacheEnDisco() =>
      BuiltInMapCachingProvider.getOrCreateInstance(
        maxCacheSize: tamanoMaximoCache,
      );

  /// A fresh provider per [TileLayer], since the layer disposes it.
  @visibleForTesting
  TileProvider proveedorTiles() =>
      _tileProvider ??
      NetworkTileProvider(
        httpClient: _clienteTiles,
        cachingProvider: _cacheTiles(),
      );

  @override
  Widget construirMapa({
    required PuntoGeografico centro,
    double zoom = zoomPorDefecto,
    List<MarcadorLugar> marcadores = const [],
    required void Function(int lugarId) alTocarMarcador,
    EventosMapa eventos = const EventosMapa(),
    PuntoGeografico? ubicacionUsuario,
  }) {
    final alMoverCamara = eventos.alMoverCamara;
    final alCamaraQuieta = eventos.alCamaraQuieta;
    final alErrorTile = eventos.alErrorTile;
    final alTileCargado = eventos.alTileCargado;
    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(centro.latitud, centro.longitud),
        initialZoom: zoom,
        onPositionChanged: alMoverCamara == null
            ? null
            : (camara, _) => alMoverCamara(_limitesDe(camara)),
        onMapEvent: alCamaraQuieta == null
            ? null
            : (evento) {
                if (_terminaGesto(evento)) {
                  alCamaraQuieta(_limitesDe(evento.camera));
                }
              },
      ),
      children: [
        TileLayer(
          urlTemplate: urlTiles,
          userAgentPackageName: userAgent,
          tileProvider: proveedorTiles(),
          errorTileCallback: alErrorTile == null
              ? null
              : (_, _, _) => alErrorTile(),
          tileBuilder: alTileCargado == null
              ? null
              : (_, tile, imagen) =>
                    _AvisoTileCargado(imagen, alTileCargado, child: tile),
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
                width: _tamanoUbicacion,
                height: _tamanoUbicacion,
                child: const Icon(
                  Icons.circle,
                  key: ValueKey('ubicacion-usuario'),
                  color: _colorUbicacion,
                  size: _tamanoUbicacion,
                ),
              ),
          ],
        ),
        const RichAttributionWidget(
          attributions: [TextSourceAttribution(atribucion)],
        ),
        if (alCamaraQuieta != null) _AvisoMapaListo(alCamaraQuieta),
      ],
    );
  }

  static LimitesMapa _limitesDe(MapCamera camara) {
    final b = camara.visibleBounds;
    return LimitesMapa(
      norte: b.north,
      sur: b.south,
      este: b.east,
      oeste: b.west,
    );
  }

  static bool _terminaGesto(MapEvent e) =>
      e is MapEventMoveEnd ||
      e is MapEventFlingAnimationEnd ||
      e is MapEventDoubleTapZoomEnd ||
      e is MapEventScrollWheelZoom;
}

/// Calls [alCargar] once its tile has loaded without error.
class _AvisoTileCargado extends StatefulWidget {
  final TileImage tile;
  final VoidCallback alCargar;
  final Widget child;

  const _AvisoTileCargado(this.tile, this.alCargar, {required this.child});

  @override
  State<_AvisoTileCargado> createState() => _AvisoTileCargadoState();
}

class _AvisoTileCargadoState extends State<_AvisoTileCargado> {
  bool _avisado = false;

  @override
  void initState() {
    super.initState();
    widget.tile.addListener(_revisar);
    WidgetsBinding.instance.addPostFrameCallback((_) => _revisar());
  }

  void _revisar() {
    final tile = widget.tile;
    if (_avisado || !mounted) return;
    if (tile.loadFinishedAt != null && !tile.loadError) {
      _avisado = true;
      widget.alCargar();
    }
  }

  @override
  void dispose() {
    widget.tile.removeListener(_revisar);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Reports the initial bounds once, right after the first frame of the map.
class _AvisoMapaListo extends StatefulWidget {
  final void Function(LimitesMapa limites) alListo;

  const _AvisoMapaListo(this.alListo);

  @override
  State<_AvisoMapaListo> createState() => _AvisoMapaListoState();
}

class _AvisoMapaListoState extends State<_AvisoMapaListo> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.alListo(FlutterMapAdapter._limitesDe(MapCamera.of(context)));
      }
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
