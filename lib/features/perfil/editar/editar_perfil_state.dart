import 'package:equatable/equatable.dart';

import '../../../core/models/user_model.dart';

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
  final UserModel usuario;

  const EditarPerfilGuardado(this.usuario);

  @override
  List<Object?> get props => [usuario];
}

class EditarPerfilFallido extends EditarPerfilState {
  final String mensaje;

  const EditarPerfilFallido(this.mensaje);

  @override
  List<Object?> get props => [mensaje];
}
