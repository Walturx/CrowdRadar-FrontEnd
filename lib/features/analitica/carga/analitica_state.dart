import 'package:equatable/equatable.dart';

/// Shared by the three analytics screens: "no data" is a normal outcome
/// (HTTP 200), not an error.
sealed class AnaliticaState<T> extends Equatable {
  const AnaliticaState();

  @override
  List<Object?> get props => const [];
}

class AnaliticaCargando<T> extends AnaliticaState<T> {
  const AnaliticaCargando();
}

class AnaliticaCargado<T> extends AnaliticaState<T> {
  final T datos;

  const AnaliticaCargado(this.datos);

  @override
  List<Object?> get props => [datos];
}

/// The backend `mensaje` explaining why there is nothing to show.
class AnaliticaSinDatos<T> extends AnaliticaState<T> {
  final String? mensaje;

  const AnaliticaSinDatos(this.mensaje);

  @override
  List<Object?> get props => [mensaje];
}

class AnaliticaError<T> extends AnaliticaState<T> {
  final String mensaje;
  final String? codigo;
  final bool esSinConexion;

  const AnaliticaError(this.mensaje, {this.codigo, this.esSinConexion = false});

  @override
  List<Object?> get props => [mensaje, codigo, esSinConexion];
}
