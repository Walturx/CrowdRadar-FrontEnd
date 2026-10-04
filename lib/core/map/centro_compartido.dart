import 'tipos_mapa.dart';

/// Last centre the map reported, shared with the other tabs (the validation
/// list looks for reports around it). Defaults to the centre of Lima.
class CentroMapaCompartido {
  static const PuntoGeografico lima = PuntoGeografico(-12.0464, -77.0428);

  PuntoGeografico? _ultimo;

  PuntoGeografico get actual => _ultimo ?? lima;

  void actualizar(LimitesMapa limites) {
    _ultimo = PuntoGeografico(
      (limites.norte + limites.sur) / 2,
      (limites.este + limites.oeste) / 2,
    );
  }
}
