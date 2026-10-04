import '../../../core/map/tipos_mapa.dart';
import '../../../core/models/lugar_resumen.dart';

/// Map markers for [lugares]: same coordinates, level and name as each place.
List<MarcadorLugar> marcadoresDe(List<LugarResumen> lugares) => [
  for (final l in lugares)
    MarcadorLugar(
      lugarId: l.id,
      latitud: l.latitud,
      longitud: l.longitud,
      nivel: l.saturacion,
      etiqueta: l.nombre,
    ),
];
