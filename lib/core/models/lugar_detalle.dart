import 'package:equatable/equatable.dart';

import 'categoria_lugar.dart';
import 'enum_api.dart';
import '../utils/lectura_json.dart';
import 'nivel_saturacion.dart';

/// Current crowding block of a place detail.
class SaturacionLugar extends Equatable {
  final NivelSaturacion nivel;
  final DateTime? actualizadoEn;
  final int reportesRecientes;
  final String? mensaje;

  const SaturacionLugar({
    this.nivel = NivelSaturacion.sinInformacion,
    this.actualizadoEn,
    this.reportesRecientes = 0,
    this.mensaje,
  });

  factory SaturacionLugar.fromJson(Map<String, dynamic> j) => SaturacionLugar(
    nivel: NivelSaturacion.desdeApi(j['nivel']),
    actualizadoEn: aFecha(j['actualizadoEn']),
    reportesRecientes: aInt(j['reportesRecientes']),
    mensaje: j['mensaje'] as String?,
  );

  @override
  List<Object?> get props => [nivel, actualizadoEn, reportesRecientes, mensaje];
}

class LugarDetalle extends Equatable {
  final int id;
  final String nombre;
  final CategoriaLugar? categoria;
  final String? direccion;
  final double latitud;
  final double longitud;
  final bool? abiertoAhora;
  final String? horarioAtencion;
  final String? urlFoto;
  final SaturacionLugar saturacion;
  final bool esFavorito;
  final bool alertasActivadas;

  const LugarDetalle({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.latitud,
    required this.longitud,
    this.direccion,
    this.abiertoAhora,
    this.horarioAtencion,
    this.urlFoto,
    this.saturacion = const SaturacionLugar(),
    this.esFavorito = false,
    this.alertasActivadas = false,
  });

  factory LugarDetalle.fromJson(Map<String, dynamic> j) => LugarDetalle(
    id: aInt(j['id']),
    nombre: j['nombre'] as String? ?? '',
    categoria: enumDesdeApi(CategoriaLugar.values, j['categoria']),
    direccion: j['direccion'] as String?,
    latitud: aDouble(j['latitud']),
    longitud: aDouble(j['longitud']),
    abiertoAhora: j['abiertoAhora'] as bool?,
    horarioAtencion: j['horarioAtencion'] as String?,
    urlFoto: j['urlFoto'] as String?,
    saturacion: SaturacionLugar.fromJson(aMapa(j['saturacion'])),
    esFavorito: j['esFavorito'] as bool? ?? false,
    alertasActivadas: j['alertasActivadas'] as bool? ?? false,
  );

  @override
  List<Object?> get props => [
    id,
    nombre,
    categoria,
    direccion,
    latitud,
    longitud,
    abiertoAhora,
    horarioAtencion,
    urlFoto,
    saturacion,
    esFavorito,
    alertasActivadas,
  ];
}
