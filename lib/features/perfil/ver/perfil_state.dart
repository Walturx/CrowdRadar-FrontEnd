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

class PerfilCargado extends PerfilState {
  final Usuario usuario;

  const PerfilCargado(this.usuario);

  @override
  List<Object?> get props => [usuario];
}

class PerfilError extends PerfilState {
  final String mensaje;
  final String? codigo;
  final bool esSinConexion;

  const PerfilError(this.mensaje, {this.codigo, this.esSinConexion = false});

  @override
  List<Object?> get props => [mensaje, codigo, esSinConexion];
}
