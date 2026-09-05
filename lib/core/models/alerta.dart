import 'package:equatable/equatable.dart';

import '../utils/lectura_json.dart';
import 'nivel_saturacion.dart';

class Alerta extends Equatable {
  final int id;
  final int lugarId;
  final String lugarNombre;
  final NivelSaturacion nivelAnterior;
  final NivelSaturacion nivelNuevo;
  final String mensaje;
  final bool leida;
  final DateTime? fechaHora;

  const Alerta({
    required this.id,
    required this.lugarId,
    required this.lugarNombre,
    required this.nivelAnterior,
    required this.nivelNuevo,
    required this.mensaje,
    this.leida = false,
    this.fechaHora,
  });

  factory Alerta.fromJson(Map<String, dynamic> j) => Alerta(
        id: aInt(j['id']),
        lugarId: aInt(j['lugarId']),
        lugarNombre: j['lugarNombre'] as String? ?? '',
        nivelAnterior: NivelSaturacion.desdeApi(j['nivelAnterior']),
        nivelNuevo: NivelSaturacion.desdeApi(j['nivelNuevo']),
        mensaje: j['mensaje'] as String? ?? '',
        leida: j['leida'] as bool? ?? false,
        fechaHora: aFecha(j['fechaHora']),
      );

  @override
  List<Object?> get props => [
        id,
        lugarId,
        lugarNombre,
        nivelAnterior,
        nivelNuevo,
        mensaje,
        leida,
        fechaHora,
      ];
}
