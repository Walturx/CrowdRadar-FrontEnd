import 'package:equatable/equatable.dart';

sealed class CambiarPasswordState extends Equatable {
  const CambiarPasswordState();

  @override
  List<Object?> get props => const [];
}

class CambiarPasswordInicial extends CambiarPasswordState {
  const CambiarPasswordInicial();
}

class CambiarPasswordEnviando extends CambiarPasswordState {
  const CambiarPasswordEnviando();
}

class CambiarPasswordExitoso extends CambiarPasswordState {
  final String mensaje;

  const CambiarPasswordExitoso(this.mensaje);

  @override
  List<Object?> get props => [mensaje];
}

class CambiarPasswordFallido extends CambiarPasswordState {
  final String mensaje;

  /// Unmet password requirements (client or server side), one text each.
  final List<String> requisitosIncumplidos;
  final String? codigo;
  final bool esSinConexion;

  const CambiarPasswordFallido(
    this.mensaje, {
    this.requisitosIncumplidos = const [],
    this.codigo,
    this.esSinConexion = false,
  });

  @override
  List<Object?> get props => [
        mensaje,
        requisitosIncumplidos,
        codigo,
        esSinConexion,
      ];
}
