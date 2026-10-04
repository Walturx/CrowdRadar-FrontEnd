import 'package:equatable/equatable.dart';

import '../../../core/models/user_model.dart';

sealed class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => const [];
}

class LoginInicial extends LoginState {
  const LoginInicial();
}

class LoginEnviando extends LoginState {
  const LoginEnviando();
}

class LoginExitoso extends LoginState {
  final UserModel usuario;

  const LoginExitoso(this.usuario);

  @override
  List<Object?> get props => [usuario];
}

class LoginFallido extends LoginState {
  final String mensaje;
  final String? codigo;
  final bool esSinConexion;

  const LoginFallido(this.mensaje, {this.codigo, this.esSinConexion = false});

  @override
  List<Object?> get props => [mensaje, codigo, esSinConexion];
}
