import 'package:equatable/equatable.dart';

import '../../../core/models/user_model.dart';

sealed class PerfilState extends Equatable {
  const PerfilState();

  @override
  List<Object?> get props => const [];
}

class PerfilCargando extends PerfilState {
  const PerfilCargando();
}

class PerfilCargado extends PerfilState {
  final UserModel usuario;

  const PerfilCargado(this.usuario);

  @override
  List<Object?> get props => [usuario];
}

class PerfilError extends PerfilState {
  final String mensaje;

  const PerfilError(this.mensaje);

  @override
  List<Object?> get props => [mensaje];
}
