import 'package:equatable/equatable.dart';

import 'lectura_json.dart';
import 'nivel_saturacion.dart';

class PuntoSerie extends Equatable {
  final String etiqueta;
  final double valor;

  const PuntoSerie(this.etiqueta, this.valor);

  factory PuntoSerie.fromJson(Map<String, dynamic> j) =>
      PuntoSerie(j['etiqueta'] as String? ?? '', aDouble(j['valor']));

  @override
  List<Object?> get props => [etiqueta, valor];
}

/// Crowding series; `sinDatos` is a 200 response, not an error.
class SerieSaturacion extends Equatable {
  final List<PuntoSerie> puntos;
  final bool sinDatos;
  final String? mensaje;

  const SerieSaturacion({
    this.puntos = const [],
    this.sinDatos = false,
    this.mensaje,
  });

  factory SerieSaturacion.fromJson(Map<String, dynamic> j) => SerieSaturacion(
        puntos: [
          for (final p in j['puntos'] as List? ?? const [])
            PuntoSerie.fromJson(aMapa(p)),
        ],
        sinDatos: j['sinDatos'] as bool? ?? false,
        mensaje: j['mensaje'] as String?,
      );

  @override
  List<Object?> get props => [puntos, sinDatos, mensaje];
}

class ComparacionPeriodos extends Equatable {
  final SerieSaturacion periodoA;
  final SerieSaturacion periodoB;

  const ComparacionPeriodos(this.periodoA, this.periodoB);

  factory ComparacionPeriodos.fromJson(Map<String, dynamic> j) =>
      ComparacionPeriodos(
        SerieSaturacion.fromJson(aMapa(j['periodoA'])),
        SerieSaturacion.fromJson(aMapa(j['periodoB'])),
      );

  @override
  List<Object?> get props => [periodoA, periodoB];
}

class FranjaHoraria extends Equatable {
  final int horaInicio;
  final int horaFin;
  final NivelSaturacion nivel;

  const FranjaHoraria(this.horaInicio, this.horaFin, this.nivel);

  factory FranjaHoraria.fromJson(Map<String, dynamic> j) => FranjaHoraria(
        aInt(j['horaInicio']),
        aInt(j['horaFin']),
        NivelSaturacion.desdeApi(j['nivel']),
      );

  @override
  List<Object?> get props => [horaInicio, horaFin, nivel];
}

class MejorHorario extends Equatable {
  final List<FranjaHoraria> franjas;
  final bool sinDatos;
  final String? mensaje;

  const MejorHorario({
    this.franjas = const [],
    this.sinDatos = false,
    this.mensaje,
  });

  factory MejorHorario.fromJson(Map<String, dynamic> j) => MejorHorario(
        franjas: [
          for (final f in j['franjas'] as List? ?? const [])
            FranjaHoraria.fromJson(aMapa(f)),
        ],
        sinDatos: j['sinDatos'] as bool? ?? false,
        mensaje: j['mensaje'] as String?,
      );

  @override
  List<Object?> get props => [franjas, sinDatos, mensaje];
}
