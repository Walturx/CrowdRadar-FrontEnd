import 'package:equatable/equatable.dart';

import 'motivo_cierre.dart';
import 'usuario_sesion.dart';

sealed class SesionState extends Equatable {
  const SesionState();
}

class SesionAutenticada extends SesionState {
  final UsuarioSesion usuario;
  final bool esAdmin;

  const SesionAutenticada({required this.usuario, required this.esAdmin});

  @override
  List<Object?> get props => [usuario, esAdmin];
}

class SesionNoAutenticada extends SesionState {
  final MotivoCierre? motivo;

  const SesionNoAutenticada({this.motivo});

  @override
  List<Object?> get props => [motivo];
}
