import 'package:equatable/equatable.dart';

import '../models/nivel_saturacion.dart';

/// Map-library-agnostic coordinate (features never touch `latlong2`).
class PuntoGeografico extends Equatable {
  final double latitud;
  final double longitud;

  const PuntoGeografico(this.latitud, this.longitud);

  @override
  List<Object?> get props => [latitud, longitud];
}

/// Visible area of the map, used to query places by bounding box.
class LimitesMapa extends Equatable {
  final double norte;
  final double sur;
  final double este;
  final double oeste;

  const LimitesMapa({
    required this.norte,
    required this.sur,
    required this.este,
    required this.oeste,
  });

  @override
  List<Object?> get props => [norte, sur, este, oeste];
}

/// Parameter object with the map notifications a screen can listen to.
///
/// [alMoverCamara] fires continuously while the camera moves; [alCamaraQuieta]
/// fires once the map is ready and after each gesture ends; [alErrorTile] fires
/// for every tile that fails to load (typically no connection) and
/// [alTileCargado] for every tile that loads (the connection is back).
class EventosMapa {
  final void Function(LimitesMapa limites)? alMoverCamara;
  final void Function(LimitesMapa limites)? alCamaraQuieta;
  final void Function()? alErrorTile;
  final void Function()? alTileCargado;

  const EventosMapa({
    this.alMoverCamara,
    this.alCamaraQuieta,
    this.alErrorTile,
    this.alTileCargado,
  });
}

class MarcadorLugar extends Equatable {
  final int lugarId;
  final double latitud;
  final double longitud;
  final NivelSaturacion nivel;
  final String etiqueta;

  const MarcadorLugar({
    required this.lugarId,
    required this.latitud,
    required this.longitud,
    required this.nivel,
    required this.etiqueta,
  });

  @override
  List<Object?> get props => [lugarId, latitud, longitud, nivel, etiqueta];
}
