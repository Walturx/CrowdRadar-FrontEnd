import 'package:equatable/equatable.dart';

import '../../../core/models/lugar_resumen.dart';

sealed class BuscarLugarState extends Equatable {
  const BuscarLugarState();

  @override
  List<Object?> get props => const [];
}

/// Nothing searched yet, or the text is too short to search.
class BuscarInicial extends BuscarLugarState {
  const BuscarInicial();
}

class BuscarBuscando extends BuscarLugarState {
  const BuscarBuscando();
}

class BuscarResultados extends BuscarLugarState {
  final List<LugarResumen> lugares;
  final String consulta;

  const BuscarResultados(this.lugares, {required this.consulta});

  @override
  List<Object?> get props => [lugares, consulta];
}

class BuscarSinResultados extends BuscarLugarState {
  final String consulta;

  /// Message sent by the server for the empty result, when there is one.
  final String? mensajeServidor;

  const BuscarSinResultados(this.consulta, {this.mensajeServidor});

  /// The server message, else the HU 3.4 text built from [consulta].
  String get mensaje => (mensajeServidor?.isNotEmpty ?? false)
      ? mensajeServidor!
      : 'No encontramos lugares para “$consulta”. Prueba con otro nombre.';

  @override
  List<Object?> get props => [consulta, mensajeServidor];
}

class BuscarError extends BuscarLugarState {
  final String mensaje;
  final String consulta;
  final String? codigo;
  final bool esSinConexion;

  const BuscarError(
    this.mensaje, {
    required this.consulta,
    this.codigo,
    this.esSinConexion = false,
  });

  @override
  List<Object?> get props => [mensaje, consulta, codigo, esSinConexion];
}
