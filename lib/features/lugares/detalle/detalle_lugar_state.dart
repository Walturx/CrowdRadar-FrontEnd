import 'package:equatable/equatable.dart';

import '../../../core/models/lugar_detalle.dart';

sealed class DetalleLugarState extends Equatable {
  const DetalleLugarState();

  @override
  List<Object?> get props => const [];
}

class DetalleCargando extends DetalleLugarState {
  const DetalleCargando();
}

/// [esFavorito] is tracked here (not in [detalle]) so toggling it never
/// requires rebuilding the shared model; [errorFavorito] is the last toggle failure.
class DetalleCargado extends DetalleLugarState {
  final LugarDetalle detalle;
  final bool esFavorito;
  final bool procesandoFavorito;
  final String? errorFavorito;

  const DetalleCargado(
    this.detalle, {
    required this.esFavorito,
    this.procesandoFavorito = false,
    this.errorFavorito,
  });

  @override
  List<Object?> get props => [
    detalle,
    esFavorito,
    procesandoFavorito,
    errorFavorito,
  ];
}

class DetalleError extends DetalleLugarState {
  static const String codigoNoEncontrado = 'LUGAR_NO_ENCONTRADO';

  final String mensaje;
  final String? codigo;
  final bool esSinConexion;

  const DetalleError(this.mensaje, {this.codigo, this.esSinConexion = false});

  /// The place does not exist (any more): retrying cannot help.
  bool get esNoEncontrado => codigo == codigoNoEncontrado;

  @override
  List<Object?> get props => [mensaje, codigo, esSinConexion];
}
