import 'package:equatable/equatable.dart';

import '../utils/lectura_json.dart';
import 'categoria_lugar.dart';
import 'enum_api.dart';
import 'nivel_saturacion.dart';

enum TipoAccionValidacion { confirmar, rechazar }

enum MotivoDenuncia { informacionFalsa, spam, contenidoInapropiado, otro }

enum EstadoValidacion { sinValidaciones, enValidacion, validado, rechazado }

/// Reliability level of a report (`INSUFICIENTE` while there are too few votes).
enum NivelConfiabilidad { alta, media, baja, insuficiente }

/// The reliability block shared by every M5 response. Counts are raw votes;
/// [porcentaje] is weighted and null while the level is `insuficiente`.
class Confiabilidad extends Equatable {
  final double? porcentaje;
  final NivelConfiabilidad nivel;
  final int confirmaciones;
  final int rechazos;
  final String? advertencia;

  const Confiabilidad({
    required this.porcentaje,
    required this.nivel,
    this.confirmaciones = 0,
    this.rechazos = 0,
    this.advertencia,
  });

  factory Confiabilidad.fromJson(Map<String, dynamic> j) => Confiabilidad(
    porcentaje: j['porcentaje'] is num ? aDouble(j['porcentaje']) : null,
    nivel:
        enumDesdeApi(NivelConfiabilidad.values, j['nivel']) ??
        NivelConfiabilidad.insuficiente,
    confirmaciones: aInt(j['confirmaciones']),
    rechazos: aInt(j['rechazos']),
    advertencia: aTexto(j['advertencia']),
  );

  @override
  List<Object?> get props => [
    porcentaje,
    nivel,
    confirmaciones,
    rechazos,
    advertencia,
  ];
}

class LugarReporte extends Equatable {
  final int id;
  final String nombre;
  final CategoriaLugar? categoria;

  const LugarReporte({required this.id, required this.nombre, this.categoria});

  factory LugarReporte.fromJson(Map<String, dynamic> j) => LugarReporte(
    id: aInt(j['id']),
    nombre: aTexto(j['nombre']) ?? '',
    categoria: enumDesdeApi(CategoriaLugar.values, j['categoria']),
  );

  @override
  List<Object?> get props => [id, nombre, categoria];
}

Confiabilidad _confiabilidad(Object? o) => Confiabilidad.fromJson(aMapa(o));

/// One item of `GET /api/validaciones/pendientes`.
class ReportePendiente extends Equatable {
  final int id;
  final LugarReporte lugar;
  final NivelSaturacion nivel;
  final DateTime? fechaHora;
  final int? distanciaMetros;
  final Confiabilidad confiabilidad;

  const ReportePendiente({
    required this.id,
    required this.lugar,
    required this.nivel,
    required this.confiabilidad,
    this.fechaHora,
    this.distanciaMetros,
  });

  factory ReportePendiente.fromJson(Map<String, dynamic> j) => ReportePendiente(
    id: aInt(j['id']),
    lugar: LugarReporte.fromJson(aMapa(j['lugar'])),
    nivel: NivelSaturacion.desdeApi(j['nivel']),
    fechaHora: aFecha(j['fechaHora']),
    distanciaMetros: j['distanciaMetros'] is num
        ? aInt(j['distanciaMetros'])
        : null,
    confiabilidad: _confiabilidad(j['confiabilidad']),
  );

  @override
  List<Object?> get props => [
    id,
    lugar,
    nivel,
    fechaHora,
    distanciaMetros,
    confiabilidad,
  ];
}

/// `GET /api/reportes/:id`: a report plus what the caller already did with it.
class DetalleReporte extends Equatable {
  final int id;
  final LugarReporte lugar;
  final NivelSaturacion nivel;
  final DateTime? fechaHora;
  final Confiabilidad confiabilidad;
  final EstadoValidacion estadoValidacion;
  final TipoAccionValidacion? miValidacion;
  final bool yaDenunciado;
  final bool esPropio;

  const DetalleReporte({
    required this.id,
    required this.lugar,
    required this.nivel,
    required this.confiabilidad,
    this.fechaHora,
    this.estadoValidacion = EstadoValidacion.sinValidaciones,
    this.miValidacion,
    this.yaDenunciado = false,
    this.esPropio = false,
  });

  factory DetalleReporte.fromJson(Map<String, dynamic> j) => DetalleReporte(
    id: aInt(j['id']),
    lugar: LugarReporte.fromJson(aMapa(j['lugar'])),
    nivel: NivelSaturacion.desdeApi(j['nivel']),
    fechaHora: aFecha(j['fechaHora']),
    confiabilidad: _confiabilidad(j['confiabilidad']),
    estadoValidacion:
        enumDesdeApi(EstadoValidacion.values, j['estadoValidacion']) ??
        EstadoValidacion.sinValidaciones,
    miValidacion: enumDesdeApi(TipoAccionValidacion.values, j['miValidacion']),
    yaDenunciado: aBool(j['yaDenunciado']) ?? false,
    esPropio: aBool(j['esPropio']) ?? false,
  );

  DetalleReporte copyWith({
    Confiabilidad? confiabilidad,
    EstadoValidacion? estadoValidacion,
    TipoAccionValidacion? miValidacion,
    bool? yaDenunciado,
  }) => DetalleReporte(
    id: id,
    lugar: lugar,
    nivel: nivel,
    fechaHora: fechaHora,
    confiabilidad: confiabilidad ?? this.confiabilidad,
    estadoValidacion: estadoValidacion ?? this.estadoValidacion,
    miValidacion: miValidacion ?? this.miValidacion,
    yaDenunciado: yaDenunciado ?? this.yaDenunciado,
    esPropio: esPropio,
  );

  @override
  List<Object?> get props => [
    id,
    lugar,
    nivel,
    fechaHora,
    confiabilidad,
    estadoValidacion,
    miValidacion,
    yaDenunciado,
    esPropio,
  ];
}

/// `data` of `POST /api/reportes/:id/validaciones` (201).
class ResultadoVoto extends Equatable {
  final TipoAccionValidacion? accion;
  final int puntosGanados;
  final int totalKarma;
  final Confiabilidad confiabilidad;
  final EstadoValidacion estadoValidacion;

  const ResultadoVoto({
    required this.accion,
    required this.puntosGanados,
    required this.totalKarma,
    required this.confiabilidad,
    required this.estadoValidacion,
  });

  factory ResultadoVoto.fromJson(Map<String, dynamic> j) {
    final karma = aMapa(j['karma']);
    return ResultadoVoto(
      accion: enumDesdeApi(
        TipoAccionValidacion.values,
        aMapa(j['validacion'])['tipoAccion'],
      ),
      puntosGanados: aInt(karma['puntosGanados']),
      totalKarma: aInt(karma['total']),
      confiabilidad: _confiabilidad(j['confiabilidad']),
      estadoValidacion:
          enumDesdeApi(EstadoValidacion.values, j['estadoValidacion']) ??
          EstadoValidacion.sinValidaciones,
    );
  }

  @override
  List<Object?> get props => [
    accion,
    puntosGanados,
    totalKarma,
    confiabilidad,
    estadoValidacion,
  ];
}

/// One item of `GET /api/reportes/mios/validacion`.
class EstadoReporteValidacion extends Equatable {
  final int reporteId;
  final LugarReporte lugar;
  final NivelSaturacion nivel;
  final DateTime? fechaHora;
  final Confiabilidad confiabilidad;
  final EstadoValidacion estadoValidacion;

  const EstadoReporteValidacion({
    required this.reporteId,
    required this.lugar,
    required this.nivel,
    required this.confiabilidad,
    required this.estadoValidacion,
    this.fechaHora,
  });

  int get confirmaciones => confiabilidad.confirmaciones;
  int get rechazos => confiabilidad.rechazos;

  factory EstadoReporteValidacion.fromJson(Map<String, dynamic> j) =>
      EstadoReporteValidacion(
        reporteId: aInt(j['reporteId']),
        lugar: LugarReporte.fromJson(aMapa(j['lugar'])),
        nivel: NivelSaturacion.desdeApi(j['nivel']),
        fechaHora: aFecha(j['fechaHora']),
        confiabilidad: _confiabilidad(j['confiabilidad']),
        estadoValidacion:
            enumDesdeApi(EstadoValidacion.values, j['estadoValidacion']) ??
            EstadoValidacion.sinValidaciones,
      );

  @override
  List<Object?> get props => [
    reporteId,
    lugar,
    nivel,
    fechaHora,
    confiabilidad,
    estadoValidacion,
  ];
}
