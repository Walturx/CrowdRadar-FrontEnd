import 'package:equatable/equatable.dart';

import '../../../core/models/lugar_resumen.dart';

sealed class MapaState extends Equatable {
  const MapaState();

  @override
  List<Object?> get props => const [];
}

/// Loading the visible area; [lugares] are the previous markers, kept so the
/// map does not blink while the camera moves.
class MapaCargando extends MapaState {
  final List<LugarResumen> lugares;

  const MapaCargando([this.lugares = const []]);

  @override
  List<Object?> get props => [lugares];
}

/// Places of the visible area; [mensajeVacio] is set only when there are none.
class MapaCargado extends MapaState {
  final List<LugarResumen> lugares;
  final String? mensajeVacio;

  const MapaCargado(this.lugares, {this.mensajeVacio});

  @override
  List<Object?> get props => [lugares, mensajeVacio];
}

class MapaError extends MapaState {
  final String mensaje;
  final String? codigo;
  final bool esSinConexion;

  const MapaError(this.mensaje, {this.codigo, this.esSinConexion = false});

  @override
  List<Object?> get props => [mensaje, codigo, esSinConexion];
}
