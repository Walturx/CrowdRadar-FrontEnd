import 'package:equatable/equatable.dart';

import '../../../core/models/reporte_saturacion.dart';

sealed class MisReportesState extends Equatable {
  const MisReportesState();

  @override
  List<Object?> get props => const [];
}

class MisReportesCargando extends MisReportesState {
  const MisReportesCargando();
}

/// HU 4.3 c3: the user has not reported anything yet.
class MisReportesVacio extends MisReportesState {
  const MisReportesVacio();
}

class MisReportesCargado extends MisReportesState {
  final List<ReporteSaturacion> reportes;
  final bool hayMas;
  final bool cargandoMas;

  /// Failure of the last "load more"; the list already loaded stays visible.
  final String? errorMas;

  /// Failure of the last full refresh; the list already loaded stays visible.
  final String? errorActualizacion;

  const MisReportesCargado(
    this.reportes, {
    this.hayMas = false,
    this.cargandoMas = false,
    this.errorMas,
    this.errorActualizacion,
  });

  @override
  List<Object?> get props => [
    reportes,
    hayMas,
    cargandoMas,
    errorMas,
    errorActualizacion,
  ];
}

class MisReportesError extends MisReportesState {
  final String mensaje;
  final String? codigo;
  final bool esSinConexion;

  const MisReportesError(
    this.mensaje, {
    this.codigo,
    this.esSinConexion = false,
  });

  @override
  List<Object?> get props => [mensaje, codigo, esSinConexion];
}
