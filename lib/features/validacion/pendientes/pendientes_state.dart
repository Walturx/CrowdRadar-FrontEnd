import 'package:equatable/equatable.dart';

import '../../../core/location/punto_referencia.dart';
import '../../../core/models/validacion.dart';

/// The vote the user just cast, shown with the thanks and the karma earned.
class VotoRegistrado extends Equatable {
  final ReportePendiente reporte;
  final TipoAccionValidacion accion;
  final int puntosGanados;

  const VotoRegistrado({
    required this.reporte,
    required this.accion,
    required this.puntosGanados,
  });

  @override
  List<Object?> get props => [reporte, accion, puntosGanados];
}

sealed class PendientesState extends Equatable {
  const PendientesState();

  @override
  List<Object?> get props => const [];
}

class PendientesCargando extends PendientesState {
  const PendientesCargando();
}

class PendientesCargado extends PendientesState {
  /// Reports still waiting for the user's vote; the first one is on screen.
  final List<ReportePendiente> reportes;

  /// Ids with a vote in flight (already removed from [reportes]).
  final Set<int> votando;
  final VotoRegistrado? ultimoVoto;

  /// Notice for the user (failed vote, already voted, soft refresh error).
  final String? aviso;

  /// Point the reports were searched around (CRO-65); the page says so when
  /// it is the map centre instead of the device.
  final OrigenReferencia origen;

  const PendientesCargado({
    required this.reportes,
    this.votando = const {},
    this.ultimoVoto,
    this.aviso,
    this.origen = OrigenReferencia.dispositivo,
  });

  @override
  List<Object?> get props => [reportes, votando, ultimoVoto, aviso, origen];
}

class PendientesError extends PendientesState {
  final String mensaje;
  final String? codigo;
  final bool esSinConexion;

  const PendientesError(
    this.mensaje, {
    this.codigo,
    this.esSinConexion = false,
  });

  @override
  List<Object?> get props => [mensaje, codigo, esSinConexion];
}
