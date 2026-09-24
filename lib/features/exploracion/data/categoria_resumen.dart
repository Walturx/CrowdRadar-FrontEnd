import 'package:equatable/equatable.dart';

import '../../../core/models/categoria_lugar.dart';
import '../../../core/models/enum_api.dart';
import '../../../core/utils/lectura_json.dart';

/// One entry of `GET /api/lugares/categorias`: a category with its label and
/// how many places it has (zero is valid).
class CategoriaResumen extends Equatable {
  final CategoriaLugar? categoria;
  final String etiqueta;
  final int total;

  const CategoriaResumen({
    required this.categoria,
    required this.etiqueta,
    required this.total,
  });

  factory CategoriaResumen.fromJson(Map<String, dynamic> j) => CategoriaResumen(
    categoria: enumDesdeApi(CategoriaLugar.values, j['categoria']),
    etiqueta: j['etiqueta'] as String? ?? '',
    total: aInt(j['total']),
  );

  @override
  List<Object?> get props => [categoria, etiqueta, total];
}
