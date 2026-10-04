import 'package:equatable/equatable.dart';

import '../utils/lectura_json.dart';
import 'nivel_saturacion.dart';

/// Grouping of `GET /api/lugares/:id/historial` (wire values `HORA` | `DIA`).
enum AgrupacionHistorial { hora, dia }

/// `9` -> `09:00`.
String etiquetaHora(int hora) => '${hora.toString().padLeft(2, '0')}:00';

/// Accepts `9` or `"09:00"`.
int _aHora(Object? o) =>
    o is String ? int.tryParse(o.split(':').first) ?? 0 : aInt(o);

class PuntoSerie extends Equatable {
  final String etiqueta;
  final double valor;
  final int muestras;

  const PuntoSerie(this.etiqueta, this.valor, {this.muestras = 0});

  /// Accepts `{etiqueta, valor, muestras}` (history) and `{hora, valor,
  /// muestras}` (one of the 24 slots of a comparison period).
  factory PuntoSerie.fromJson(Map<String, dynamic> j) => PuntoSerie(
    aTexto(j['etiqueta']) ??
        (j['hora'] == null ? '' : etiquetaHora(_aHora(j['hora']))),
    aDouble(j['valor']),
    muestras: aInt(j['muestras']),
  );

  @override
  List<Object?> get props => [etiqueta, valor, muestras];
}

/// Crowding series; `sinDatos` is a 200 response, not an error. The backend
/// sends `hayDatos`; the frozen `sinDatos` is derived from it.
class SerieSaturacion extends Equatable {
  final List<PuntoSerie> puntos;
  final bool sinDatos;
  final String? mensaje;

  /// True when the data is synthetic demo data (disclosed to the user).
  final bool sintetico;

  const SerieSaturacion({
    this.puntos = const [],
    this.sinDatos = false,
    this.mensaje,
    this.sintetico = false,
  });

  factory SerieSaturacion.fromJson(Map<String, dynamic> j) => SerieSaturacion(
    puntos: _puntos(j['puntos']),
    sinDatos: aBool(j['sinDatos']) ?? aBool(j['hayDatos']) == false,
    mensaje: aTexto(j['mensaje']),
    sintetico: j['sintetico'] == true,
  );

  @override
  List<Object?> get props => [puntos, sinDatos, mensaje, sintetico];
}

List<PuntoSerie> _puntos(Object? lista) => [
  for (final p in aLista(lista)) PuntoSerie.fromJson(aMapa(p)),
];

class DiferenciaHora extends Equatable {
  final int hora;

  /// Period B minus period A (positive: B is busier than A).
  final double diferencia;

  const DiferenciaHora(this.hora, this.diferencia);

  /// Named reading of [diferencia]: how much busier B is than A.
  double get diferenciaRespectoA => diferencia;

  @override
  List<Object?> get props => [hora, diferencia];
}

class ComparacionPeriodos extends Equatable {
  final SerieSaturacion periodoA;
  final SerieSaturacion periodoB;

  /// Per hour, [DiferenciaHora.diferenciaRespectoA] (B minus A).
  final List<DiferenciaHora> diferencias;
  final String? resumen;
  final bool suficiente;
  final String? mensaje;

  const ComparacionPeriodos(
    this.periodoA,
    this.periodoB, {
    this.diferencias = const [],
    this.resumen,
    this.suficiente = true,
    this.mensaje,
  });

  bool get sinDatos => !suficiente || periodoA.sinDatos || periodoB.sinDatos;

  bool get sintetico => periodoA.sintetico || periodoB.sintetico;

  /// Periods arrive either as the 24 hourly slots (backend) or as a series.
  factory ComparacionPeriodos.fromJson(Map<String, dynamic> j) {
    SerieSaturacion periodo(Object? o) => o is List
        ? SerieSaturacion(puntos: _puntos(o))
        : SerieSaturacion.fromJson(aMapa(o));
    return ComparacionPeriodos(
      periodo(j['periodoA']),
      periodo(j['periodoB']),
      diferencias: [
        for (final d in aLista(j['diferencias']))
          DiferenciaHora(
            _aHora(aMapa(d)['hora']),
            aDouble(aMapa(d)['diferencia']),
          ),
      ],
      resumen: aTexto(j['resumen']),
      suficiente: aBool(j['suficiente']) ?? true,
      mensaje: aTexto(j['mensaje']),
    );
  }

  @override
  List<Object?> get props => [
    periodoA,
    periodoB,
    diferencias,
    resumen,
    suficiente,
    mensaje,
  ];
}

class FranjaHoraria extends Equatable {
  final int horaInicio;
  final int horaFin;
  final NivelSaturacion nivel;
  final double? promedio;
  final int? muestras;

  const FranjaHoraria(
    this.horaInicio,
    this.horaFin,
    this.nivel, {
    this.promedio,
    this.muestras,
  });

  factory FranjaHoraria.fromJson(Map<String, dynamic> j) => FranjaHoraria(
    _aHora(j['horaInicio']),
    _aHora(j['horaFin']),
    NivelSaturacion.desdeApi(j['nivel']),
    promedio: j['promedio'] is num ? aDouble(j['promedio']) : null,
    muestras: j['muestras'] is num ? aInt(j['muestras']) : null,
  );

  @override
  List<Object?> get props => [horaInicio, horaFin, nivel, promedio, muestras];
}

class MejorHorario extends Equatable {
  final List<FranjaHoraria> franjas;
  final bool sinDatos;
  final String? mensaje;
  final bool sintetico;

  const MejorHorario({
    this.franjas = const [],
    this.sinDatos = false,
    this.mensaje,
    this.sintetico = false,
  });

  /// The backend sends `recomendaciones` + `suficiente`.
  factory MejorHorario.fromJson(Map<String, dynamic> j) => MejorHorario(
    franjas: [
      for (final f in aLista(j['recomendaciones'] ?? j['franjas']))
        FranjaHoraria.fromJson(aMapa(f)),
    ],
    sinDatos: aBool(j['sinDatos']) ?? aBool(j['suficiente']) == false,
    mensaje: aTexto(j['mensaje']),
    sintetico: j['sintetico'] == true,
  );

  @override
  List<Object?> get props => [franjas, sinDatos, mensaje, sintetico];
}
