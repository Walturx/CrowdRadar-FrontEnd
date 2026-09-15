import 'package:equatable/equatable.dart';

sealed class RecuperarState extends Equatable {
  const RecuperarState();

  @override
  List<Object?> get props => const [];
}

class RecuperarInicial extends RecuperarState {
  const RecuperarInicial();
}

class RecuperarEnviando extends RecuperarState {
  const RecuperarEnviando();
}

class RecuperarEnviado extends RecuperarState {
  final String mensaje;

  const RecuperarEnviado(this.mensaje);

  @override
  List<Object?> get props => [mensaje];
}

class RecuperarFallido extends RecuperarState {
  final String mensaje;
  final String? codigo;
  final bool esSinConexion;

  const RecuperarFallido(this.mensaje, {this.codigo, this.esSinConexion = false});

  @override
  List<Object?> get props => [mensaje, codigo, esSinConexion];
}
