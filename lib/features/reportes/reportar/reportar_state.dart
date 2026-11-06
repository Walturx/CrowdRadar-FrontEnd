import 'package:equatable/equatable.dart';

import '../../../core/models/nivel_saturacion.dart';

sealed class ReportarState extends Equatable {
  const ReportarState();

  /// The level currently chosen, whatever the phase.
  NivelSaturacion? get nivel => switch (this) {
    ReportarEditando(:final nivel) => nivel,
    ReportarEnviando(:final nivel) => nivel,
    ReportarFallido(:final nivel) => nivel,
    ReportarEnviado() => null,
  };

  @override
  List<Object?> get props => const [];
}

/// The user is choosing a level; [error] is the "no level selected" validation.
class ReportarEditando extends ReportarState {
  @override
  final NivelSaturacion? nivel;
  final String? error;

  const ReportarEditando({this.nivel, this.error});

  @override
  List<Object?> get props => [nivel, error];
}

class ReportarEnviando extends ReportarState {
  @override
  final NivelSaturacion nivel;

  const ReportarEnviando(this.nivel);

  @override
  List<Object?> get props => [nivel];
}

/// The report was accepted; [mensaje] is the thanks. Sending a report earns
/// no points (they come once it is VALIDADO), so none are announced.
class ReportarEnviado extends ReportarState {
  final String mensaje;

  const ReportarEnviado({required this.mensaje});

  @override
  List<Object?> get props => [mensaje];
}

/// [bloqueante]: retrying cannot help (suspended account, place gone), so the
/// form only offers to close. [reintentable]: transient failure (offline, 5xx),
/// so the form stays and offers "Reintentar".
class ReportarFallido extends ReportarState {
  final String mensaje;
  @override
  final NivelSaturacion? nivel;
  final String? codigo;
  final bool esSinConexion;
  final bool bloqueante;
  final bool reintentable;

  const ReportarFallido(
    this.mensaje, {
    this.nivel,
    this.codigo,
    this.esSinConexion = false,
    this.bloqueante = false,
    this.reintentable = false,
  });

  @override
  List<Object?> get props => [
    mensaje,
    nivel,
    codigo,
    esSinConexion,
    bloqueante,
    reintentable,
  ];
}
