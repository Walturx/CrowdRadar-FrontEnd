import 'package:equatable/equatable.dart';

sealed class DenunciarState extends Equatable {
  const DenunciarState();

  @override
  List<Object?> get props => const [];
}

class DenunciarFormulario extends DenunciarState {
  final String? error;
  final bool enviando;

  const DenunciarFormulario({this.error, this.enviando = false});

  @override
  List<Object?> get props => [error, enviando];
}

/// HU 5.4 c2.
class DenunciarEnviado extends DenunciarState {
  const DenunciarEnviado();
}

/// The report cannot be reported (already, own, gone): only "Cerrar" is left.
class DenunciarBloqueado extends DenunciarState {
  final String mensaje;

  const DenunciarBloqueado(this.mensaje);

  @override
  List<Object?> get props => [mensaje];
}
