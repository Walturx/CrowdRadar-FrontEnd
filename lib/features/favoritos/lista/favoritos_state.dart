import 'package:equatable/equatable.dart';

import '../../../core/models/favorito.dart';

sealed class FavoritosState extends Equatable {
  const FavoritosState();

  @override
  List<Object?> get props => const [];
}

class FavoritosCargando extends FavoritosState {
  const FavoritosCargando();
}

/// The user's favorites, newest first.
///
/// [mensajeVacio] is the server explanation when there are none. [eliminado]
/// is the favorite just removed (the screen offers to undo it). [error] is a
/// soft failure of the last action or refresh: [favoritos] is still the last
/// good data. [copiar] carries [eliminado] forward (the undo must survive
/// other actions) unless `limpiarEliminado` drops it. [procesando] holds the places with an action in flight.
class FavoritosCargado extends FavoritosState {
  final List<Favorito> favoritos;
  final String mensajeVacio;
  final Favorito? eliminado;
  final String? error;
  final Set<int> procesando;

  const FavoritosCargado(
    this.favoritos, {
    this.mensajeVacio = '',
    this.eliminado,
    this.error,
    this.procesando = const {},
  });

  /// Master switch: on only when every favorite has its alerts on.
  bool get todasConAlertas =>
      favoritos.isNotEmpty && favoritos.every((f) => f.alertasActivadas);

  FavoritosCargado copiar({
    List<Favorito>? favoritos,
    String? mensajeVacio,
    Favorito? eliminado,
    bool limpiarEliminado = false,
    String? error,
    Set<int>? procesando,
  }) => FavoritosCargado(
    favoritos ?? this.favoritos,
    mensajeVacio: mensajeVacio ?? this.mensajeVacio,
    eliminado: limpiarEliminado ? null : eliminado ?? this.eliminado,
    error: error,
    procesando: procesando ?? this.procesando,
  );

  @override
  List<Object?> get props => [
    favoritos,
    mensajeVacio,
    eliminado,
    error,
    procesando,
  ];
}

class FavoritosError extends FavoritosState {
  final String mensaje;
  final String? codigo;
  final bool esSinConexion;

  const FavoritosError(this.mensaje, {this.codigo, this.esSinConexion = false});

  @override
  List<Object?> get props => [mensaje, codigo, esSinConexion];
}
