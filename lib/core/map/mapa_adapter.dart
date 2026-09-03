import 'package:flutter/widgets.dart';

import 'tipos_mapa.dart';

/// Frozen port for drawing maps. Features depend on this, never on a map SDK.
abstract class MapaAdapter {
  Widget construirMapa({
    required PuntoGeografico centro,
    double zoom = 13,
    List<MarcadorLugar> marcadores = const [],
    required void Function(int lugarId) alTocarMarcador,
    void Function(LimitesMapa limites)? alMoverCamara,
    PuntoGeografico? ubicacionUsuario,
  });
}
