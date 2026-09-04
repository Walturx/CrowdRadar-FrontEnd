import 'package:equatable/equatable.dart';

sealed class RegistroState extends Equatable {
  const RegistroState();

  @override
  List<Object?> get props => const [];
}

class RegistroInicial extends RegistroState {
  const RegistroInicial();
}

class RegistroEnviando extends RegistroState {
  const RegistroEnviando();
}

class RegistroExitoso extends RegistroState {
  const RegistroExitoso();
}

class RegistroFallido extends RegistroState {
  final String mensaje;
  final Map<String, String> erroresPorCampo;
  final String? codigo;
  final bool esSinConexion;

  const RegistroFallido(
    this.mensaje, {
    this.erroresPorCampo = const {},
    this.codigo,
    this.esSinConexion = false,
  });

  @override
  List<Object?> get props => [mensaje, erroresPorCampo, codigo, esSinConexion];
}
