import 'package:flutter/widgets.dart';

import 'tipos_mapa.dart';

/// Adapter pattern: frozen port for drawing maps. Features depend on this, never on a map SDK.
///
/// Notifications arrive through [EventosMapa].
abstract class MapaAdapter {
  Widget construirMapa({
    required PuntoGeografico centro,
    double zoom = 13,
    List<MarcadorLugar> marcadores = const [],
    required void Function(int lugarId) alTocarMarcador,
    EventosMapa eventos = const EventosMapa(),
    PuntoGeografico? ubicacionUsuario,
  });
}
