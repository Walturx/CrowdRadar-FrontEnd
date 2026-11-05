import '../map/tipos_mapa.dart';

/// Adapter pattern: port for the device location. Features depend on this,
/// never on a location plugin.
abstract class UbicacionService {
  /// Current device position, or null when it is not available: location
  /// services off, permission refused, or no fix in time. Never throws.
  Future<PuntoGeografico?> obtenerUbicacion();
}
