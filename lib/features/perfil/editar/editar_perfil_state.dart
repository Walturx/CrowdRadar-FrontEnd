import 'package:equatable/equatable.dart';

import '../../../core/models/usuario.dart';

sealed class EditarPerfilState extends Equatable {
  const EditarPerfilState();

  @override
  List<Object?> get props => const [];
}

class EditarPerfilEditando extends EditarPerfilState {
  const EditarPerfilEditando();
}

class EditarPerfilGuardando extends EditarPerfilState {
  const EditarPerfilGuardando();
}

class EditarPerfilGuardado extends EditarPerfilState {
  final Usuario usuario;

  const EditarPerfilGuardado(this.usuario);

  @override
  List<Object?> get props => [usuario];
}

class EditarPerfilFallido extends EditarPerfilState {
  final String mensaje;
  final String? codigo;
  final bool esSinConexion;

  const EditarPerfilFallido(
    this.mensaje, {
    this.codigo,
    this.esSinConexion = false,
  });

  @override
  List<Object?> get props => [mensaje, codigo, esSinConexion];
}
