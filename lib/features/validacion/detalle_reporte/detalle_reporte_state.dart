import 'package:equatable/equatable.dart';

import '../../../core/models/tier_usuario.dart';
import '../../../core/models/validacion.dart';

sealed class DetalleState extends Equatable {
  const DetalleState();

  @override
  List<Object?> get props => const [];
}

class DetalleCargando extends DetalleState {
  const DetalleCargando();
}

class DetalleCargado extends DetalleState {
  final DetalleReporte detalle;

  /// A vote is in flight.
  final bool votando;

  /// Notice for the user (thanks, already voted, failure).
  final String? aviso;

  /// Voter's own tier, shown beside the thanks (S23); set only with it, and
  /// null when the vote response carried none.
  final TierUsuario? tierVotante;

  const DetalleCargado(
    this.detalle, {
    this.votando = false,
    this.aviso,
    this.tierVotante,
  });

  @override
  List<Object?> get props => [detalle, votando, aviso, tierVotante];
}

class DetalleError extends DetalleState {
  final String mensaje;
  final String? codigo;
  final bool esSinConexion;

  const DetalleError(this.mensaje, {this.codigo, this.esSinConexion = false});

  @override
  List<Object?> get props => [mensaje, codigo, esSinConexion];
}
