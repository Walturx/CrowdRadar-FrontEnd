import 'package:equatable/equatable.dart';

import '../../../core/models/nivel_saturacion.dart';

sealed class ReportarState extends Equatable {
  const ReportarState();

  @override
  List<Object?> get props => const [];
}

/// The user is choosing a level; [error] is the "no level selected" validation.
class ReportarEditando extends ReportarState {
  final NivelSaturacion? nivel;
  final String? error;

  const ReportarEditando({this.nivel, this.error});

  @override
  List<Object?> get props => [nivel, error];
}

class ReportarEnviando extends ReportarState {
  final NivelSaturacion nivel;

  const ReportarEnviando(this.nivel);

  @override
  List<Object?> get props => [nivel];
}

/// [motivoSinPuntos] is user-facing text, only set when no karma was awarded.
class ReportarEnviado extends ReportarState {
  final String mensaje;
  final int puntosGanados;
  final int totalKarma;
  final String? motivoSinPuntos;

  const ReportarEnviado({
    required this.mensaje,
    required this.puntosGanados,
    required this.totalKarma,
    this.motivoSinPuntos,
  });

  @override
  List<Object?> get props => [
    mensaje,
    puntosGanados,
    totalKarma,
    motivoSinPuntos,
  ];
}

class ReportarFallido extends ReportarState {
  final String mensaje;
  final NivelSaturacion? nivel;
  final String? codigo;
  final bool esSinConexion;

  const ReportarFallido(
    this.mensaje, {
    this.nivel,
    this.codigo,
    this.esSinConexion = false,
  });

  @override
  List<Object?> get props => [mensaje, nivel, codigo, esSinConexion];
}
