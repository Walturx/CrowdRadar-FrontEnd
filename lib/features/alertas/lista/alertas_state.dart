import 'package:equatable/equatable.dart';

import '../../../core/models/alerta.dart';

sealed class AlertasState extends Equatable {
  const AlertasState();

  @override
  List<Object?> get props => const [];
}

class AlertasCargando extends AlertasState {
  const AlertasCargando();
}

/// The alerts of the first page (unread first) and the total unread count.
///
/// [mensajeVacio] is the server explanation when there are none. [error] is a
/// soft failure of the last action or refresh: [alertas] is still the last
/// good data.
class AlertasCargado extends AlertasState {
  final List<Alerta> alertas;
  final int noLeidas;
  final String mensajeVacio;
  final String? error;

  const AlertasCargado(
    this.alertas, {
    required this.noLeidas,
    this.mensajeVacio = '',
    this.error,
  });

  @override
  List<Object?> get props => [alertas, noLeidas, mensajeVacio, error];
}

class AlertasError extends AlertasState {
  final String mensaje;
  final String? codigo;
  final bool esSinConexion;

  const AlertasError(this.mensaje, {this.codigo, this.esSinConexion = false});

  @override
  List<Object?> get props => [mensaje, codigo, esSinConexion];
}
