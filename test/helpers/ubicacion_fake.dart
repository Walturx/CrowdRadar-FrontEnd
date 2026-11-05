import 'dart:async';

import 'package:crowdradar/core/location/ubicacion_service.dart';
import 'package:crowdradar/core/map/tipos_mapa.dart';

/// Parque Kennedy, Miraflores.
const PuntoGeografico miraflores = PuntoGeografico(-12.1219, -77.0297);

/// [UbicacionService] that answers [punto] (null = unavailable), or waits on
/// [pendiente] when set. Counts the calls.
class UbicacionServiceFake implements UbicacionService {
  PuntoGeografico? punto;
  Completer<PuntoGeografico?>? pendiente;
  int llamadas = 0;

  UbicacionServiceFake([this.punto]);

  @override
  Future<PuntoGeografico?> obtenerUbicacion() {
    llamadas++;
    return pendiente?.future ?? Future.value(punto);
  }
}
