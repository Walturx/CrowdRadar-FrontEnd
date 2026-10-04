import 'package:equatable/equatable.dart';

import '../../../core/models/validacion.dart';

enum FiltroEstadoValidacion {
  todos('Todos'),
  validados('Validados'),
  enValidacion('En validación'),
  rechazados('Rechazados');

  final String etiqueta;

  const FiltroEstadoValidacion(this.etiqueta);

  bool admite(EstadoValidacion estado) => switch (this) {
    todos => true,
    validados => estado == EstadoValidacion.validado,
    enValidacion => estado == EstadoValidacion.enValidacion,
    rechazados => estado == EstadoValidacion.rechazado,
  };
}

sealed class EstadoValidacionState extends Equatable {
  const EstadoValidacionState();

  @override
  List<Object?> get props => const [];
}

class EstadoValidacionCargando extends EstadoValidacionState {
  const EstadoValidacionCargando();
}

class EstadoValidacionCargado extends EstadoValidacionState {
  final List<EstadoReporteValidacion> reportes;
  final FiltroEstadoValidacion filtro;
  final String? errorActualizacion;

  const EstadoValidacionCargado(
    this.reportes, {
    this.filtro = FiltroEstadoValidacion.todos,
    this.errorActualizacion,
  });

  List<EstadoReporteValidacion> get visibles => [
    for (final r in reportes)
      if (filtro.admite(r.estadoValidacion)) r,
  ];

  /// Estado of one of my reports, or null when it is not in the list.
  EstadoValidacion? estadoDe(int reporteId) {
    for (final r in reportes) {
      if (r.reporteId == reporteId) return r.estadoValidacion;
    }
    return null;
  }

  @override
  List<Object?> get props => [reportes, filtro, errorActualizacion];
}

class EstadoValidacionError extends EstadoValidacionState {
  final String mensaje;
  final bool esSinConexion;

  const EstadoValidacionError(this.mensaje, {this.esSinConexion = false});

  @override
  List<Object?> get props => [mensaje, esSinConexion];
}
