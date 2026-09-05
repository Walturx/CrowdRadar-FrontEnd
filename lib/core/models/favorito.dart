import 'package:equatable/equatable.dart';

import 'categoria_lugar.dart';
import 'enum_api.dart';
import '../utils/lectura_json.dart';
import 'nivel_saturacion.dart';

class Favorito extends Equatable {
  final int lugarId;
  final String nombre;
  final CategoriaLugar? categoria;
  final NivelSaturacion saturacion;
  final bool alertasActivadas;

  const Favorito({
    required this.lugarId,
    required this.nombre,
    required this.categoria,
    this.saturacion = NivelSaturacion.sinInformacion,
    this.alertasActivadas = false,
  });

  factory Favorito.fromJson(Map<String, dynamic> j) => Favorito(
        lugarId: aInt(j['lugarId']),
        nombre: j['nombre'] as String? ?? '',
        categoria: enumDesdeApi(CategoriaLugar.values, j['categoria']),
        saturacion: NivelSaturacion.desdeApi(j['saturacion']),
        alertasActivadas: j['alertasActivadas'] as bool? ?? false,
      );

  @override
  List<Object?> get props =>
      [lugarId, nombre, categoria, saturacion, alertasActivadas];
}
