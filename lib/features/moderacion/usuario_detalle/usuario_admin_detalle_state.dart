import 'package:equatable/equatable.dart';

import '../../../core/models/moderacion.dart';

sealed class UsuarioAdminDetalleState extends Equatable {
  const UsuarioAdminDetalleState();

  @override
  List<Object?> get props => const [];
}

class UsuarioAdminDetalleCargando extends UsuarioAdminDetalleState {
  const UsuarioAdminDetalleCargando();
}

class UsuarioAdminDetalleCargado extends UsuarioAdminDetalleState {
  final DetalleUsuarioAdmin usuario;

  /// A suspension or reactivation request is in flight.
  final bool enCurso;

  /// Outcome or failure text to show once (snack bar).
  final String? aviso;

  const UsuarioAdminDetalleCargado({
    required this.usuario,
    this.enCurso = false,
    this.aviso,
  });

  @override
  List<Object?> get props => [usuario, enCurso, aviso];
}

class UsuarioAdminDetalleError extends UsuarioAdminDetalleState {
  final String mensaje;
  final String? codigo;
  final bool esSinConexion;

  const UsuarioAdminDetalleError(
    this.mensaje, {
    this.codigo,
    this.esSinConexion = false,
  });

  @override
  List<Object?> get props => [mensaje, codigo, esSinConexion];
}
