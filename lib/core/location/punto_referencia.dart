import 'package:equatable/equatable.dart';

import '../map/centro_compartido.dart';
import '../map/tipos_mapa.dart';
import 'ubicacion_service.dart';

/// Where a [Referencia] came from; the UI says so when it is not the device.
enum OrigenReferencia { dispositivo, centroMapa }

class Referencia extends Equatable {
  final PuntoGeografico punto;
  final OrigenReferencia origen;

  const Referencia(this.punto, this.origen);

  @override
  List<Object?> get props => [punto, origen];
}

/// The one point nearby searches and distances are measured from (CRO-65):
/// the device location when the user allows it, else the last map centre.
class PuntoReferencia {
  final UbicacionService _ubicacion;
  final CentroMapaCompartido _centroMapa;

  PuntoGeografico? _dispositivo;
  Future<Referencia>? _enCurso;

  PuntoReferencia(this._ubicacion, this._centroMapa);

  /// Device location from the last [actualizar], or null if it was unavailable.
  PuntoGeografico? get dispositivo => _dispositivo;

  Referencia get actual {
    final dispositivo = _dispositivo;
    return dispositivo != null
        ? Referencia(dispositivo, OrigenReferencia.dispositivo)
        : Referencia(_centroMapa.actual, OrigenReferencia.centroMapa);
  }

  /// Asks for the device location again. Overlapping calls share one request,
  /// so the permission dialog is never asked for twice at once.
  Future<Referencia> actualizar() =>
      _enCurso ??= _pedir().whenComplete(() => _enCurso = null);

  Future<Referencia> _pedir() async {
    _dispositivo = await _ubicacion.obtenerUbicacion();
    return actual;
  }
}
