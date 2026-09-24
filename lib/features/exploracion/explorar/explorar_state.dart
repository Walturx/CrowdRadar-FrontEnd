import 'package:equatable/equatable.dart';

import '../../../core/models/categoria_lugar.dart';
import '../../../core/models/nivel_saturacion.dart';
import '../data/categoria_resumen.dart';

sealed class ExplorarState extends Equatable {
  const ExplorarState();

  @override
  List<Object?> get props => const [];
}

class ExplorarCargando extends ExplorarState {
  const ExplorarCargando();
}

/// The server categories plus the filters chosen so far (null = "Todos").
class ExplorarCargado extends ExplorarState {
  final List<CategoriaResumen> categorias;
  final CategoriaLugar? categoria;
  final NivelSaturacion? saturacion;

  const ExplorarCargado(this.categorias, {this.categoria, this.saturacion});

  @override
  List<Object?> get props => [categorias, categoria, saturacion];
}

class ExplorarError extends ExplorarState {
  final String mensaje;
  final String? codigo;
  final bool esSinConexion;

  const ExplorarError(this.mensaje, {this.codigo, this.esSinConexion = false});

  @override
  List<Object?> get props => [mensaje, codigo, esSinConexion];
}
