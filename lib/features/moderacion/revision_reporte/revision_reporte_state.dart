import 'package:equatable/equatable.dart';

import '../../../core/models/moderacion.dart';

sealed class RevisionReporteState extends Equatable {
  const RevisionReporteState();

  @override
  List<Object?> get props => const [];
}

class RevisionReporteCargando extends RevisionReporteState {
  const RevisionReporteCargando();
}

class RevisionReporteCargado extends RevisionReporteState {
  final DetalleReporteDenunciado detalle;

  /// The decision is being sent; the buttons are disabled.
  final bool resolviendo;
  final String? aviso;

  const RevisionReporteCargado({
    required this.detalle,
    this.resolviendo = false,
    this.aviso,
  });

  @override
  List<Object?> get props => [detalle, resolviendo, aviso];
}

/// HU 7.1 c3: the decision was recorded; shows the new report estado.
class RevisionReporteResuelta extends RevisionReporteState {
  final DetalleReporteDenunciado detalle;
  final ResolucionReporte resolucion;

  const RevisionReporteResuelta({
    required this.detalle,
    required this.resolucion,
  });

  @override
  List<Object?> get props => [detalle, resolucion];
}

/// The report no longer has pending denuncias (resolved elsewhere) or is gone.
class RevisionReporteObsoleta extends RevisionReporteState {
  final String mensaje;

  const RevisionReporteObsoleta(this.mensaje);

  @override
  List<Object?> get props => [mensaje];
}

class RevisionReporteError extends RevisionReporteState {
  final String mensaje;
  final String? codigo;
  final bool esSinConexion;

  const RevisionReporteError(
    this.mensaje, {
    this.codigo,
    this.esSinConexion = false,
  });

  @override
  List<Object?> get props => [mensaje, codigo, esSinConexion];
}
