import 'package:equatable/equatable.dart';

import 'categoria_lugar.dart';
import 'enum_api.dart';
import 'lectura_json.dart';
import 'nivel_saturacion.dart';

/// Place as listed on the map and in search/explore results.
class LugarResumen extends Equatable {
  final int id;
  final String nombre;
  final CategoriaLugar? categoria;
  final double latitud;
  final double longitud;
  final NivelSaturacion saturacion;
  final double? distanciaMetros;

  const LugarResumen({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.latitud,
    required this.longitud,
    this.saturacion = NivelSaturacion.sinInformacion,
    this.distanciaMetros,
  });

  factory LugarResumen.fromJson(Map<String, dynamic> j) => LugarResumen(
        id: aInt(j['id']),
        nombre: j['nombre'] as String? ?? '',
        categoria: enumDesdeApi(CategoriaLugar.values, j['categoria']),
        latitud: aDouble(j['latitud']),
        longitud: aDouble(j['longitud']),
        saturacion: NivelSaturacion.desdeApi(j['saturacion']),
        distanciaMetros:
            j['distanciaMetros'] is num ? aDouble(j['distanciaMetros']) : null,
      );

  @override
  List<Object?> get props =>
      [id, nombre, categoria, latitud, longitud, saturacion, distanciaMetros];
}
