import 'package:equatable/equatable.dart';

import '../../../core/models/usuario.dart';

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
  final Usuario usuario;

  const LoginExitoso(this.usuario);

  @override
  List<Object?> get props => [usuario];
}

class LoginFallido extends LoginState {
  final String mensaje;
  final String? codigo;
  final bool esSinConexion;

  /// Seconds before another attempt is allowed (rate limit), when known.
  final int? reintentarEnSegundos;

  const LoginFallido(
    this.mensaje, {
    this.codigo,
    this.esSinConexion = false,
    this.reintentarEnSegundos,
  });

  @override
  List<Object?> get props =>
      [mensaje, codigo, esSinConexion, reintentarEnSegundos];
}
