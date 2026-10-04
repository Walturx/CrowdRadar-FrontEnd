import 'package:equatable/equatable.dart';

import '../../../core/models/usuario.dart';

sealed class PerfilState extends Equatable {
  const PerfilState();

  @override
  List<Object?> get props => const [];
}

class PerfilCargando extends PerfilState {
  const PerfilCargando();
}

/// [errorActualizacion] is a failed background refresh: [usuario] is still the
/// last good data, so the screen keeps showing it and only warns.
class PerfilCargado extends PerfilState {
  final Usuario usuario;
  final String? errorActualizacion;

  const PerfilCargado(this.usuario, {this.errorActualizacion});

  @override
  List<Object?> get props => [usuario, errorActualizacion];
}

class PerfilError extends PerfilState {
  final String mensaje;
  final String? codigo;
  final bool esSinConexion;

  const PerfilError(this.mensaje, {this.codigo, this.esSinConexion = false});

  @override
  List<Object?> get props => [mensaje, codigo, esSinConexion];
}
