import 'package:flutter/widgets.dart';

import 'tipos_mapa.dart';

/// Adapter pattern: frozen port for drawing maps. Features depend on this, never on a map SDK.
///
/// [alMoverCamara] fires continuously while the camera moves; [alCamaraQuieta]
/// fires once the map is ready and after each gesture ends.
abstract class MapaAdapter {
  Widget construirMapa({
    required PuntoGeografico centro,
    double zoom = 13,
    List<MarcadorLugar> marcadores = const [],
    required void Function(int lugarId) alTocarMarcador,
    void Function(LimitesMapa limites)? alMoverCamara,
    void Function(LimitesMapa limites)? alCamaraQuieta,
    PuntoGeografico? ubicacionUsuario,
  });
}
