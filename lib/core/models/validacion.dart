import 'package:equatable/equatable.dart';

import 'enum_api.dart';
import 'lectura_json.dart';
import 'nivel_saturacion.dart';

enum TipoAccionValidacion { confirmar, rechazar }

enum MotivoDenuncia { informacionFalsa, spam, contenidoInapropiado, otro }

enum EstadoValidacion { sinValidaciones, enValidacion, validado, rechazado }

class ReportePendiente extends Equatable {
  final int id;
  final int lugarId;
  final String lugarNombre;
  final NivelSaturacion nivel;
  final DateTime? fechaHora;
  final double? distanciaMetros;

  const ReportePendiente({
    required this.id,
    required this.lugarId,
    required this.lugarNombre,
    required this.nivel,
    this.fechaHora,
    this.distanciaMetros,
  });

  factory ReportePendiente.fromJson(Map<String, dynamic> j) => ReportePendiente(
        id: aInt(j['id']),
        lugarId: aInt(j['lugarId']),
        lugarNombre: j['lugarNombre'] as String? ?? '',
        nivel: NivelSaturacion.desdeApi(j['nivel']),
        fechaHora: aFecha(j['fechaHora']),
        distanciaMetros:
            j['distanciaMetros'] is num ? aDouble(j['distanciaMetros']) : null,
      );

  @override
  List<Object?> get props =>
      [id, lugarId, lugarNombre, nivel, fechaHora, distanciaMetros];
}

/// `GET /api/reportes/:id`: a report plus what the caller already did with it.
class DetalleReporte extends Equatable {
  final ReportePendiente reporte;
  final TipoAccionValidacion? miValidacion;
  final bool yaDenunciado;
  final bool esPropio;

  const DetalleReporte({
    required this.reporte,
    this.miValidacion,
    this.yaDenunciado = false,
    this.esPropio = false,
  });

  factory DetalleReporte.fromJson(Map<String, dynamic> j) => DetalleReporte(
        reporte: ReportePendiente.fromJson(j),
        miValidacion:
            enumDesdeApi(TipoAccionValidacion.values, j['miValidacion']),
        yaDenunciado: j['yaDenunciado'] as bool? ?? false,
        esPropio: j['esPropio'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [reporte, miValidacion, yaDenunciado, esPropio];
}

class EstadoReporteValidacion extends Equatable {
  final int reporteId;
  final EstadoValidacion estado;
  final int confirmaciones;
  final int rechazos;

  const EstadoReporteValidacion({
    required this.reporteId,
    required this.estado,
    this.confirmaciones = 0,
    this.rechazos = 0,
  });

  factory EstadoReporteValidacion.fromJson(Map<String, dynamic> j) =>
      EstadoReporteValidacion(
        reporteId: aInt(j['reporteId']),
        estado: enumDesdeApi(EstadoValidacion.values, j['estado']) ??
            EstadoValidacion.sinValidaciones,
        confirmaciones: aInt(j['confirmaciones']),
        rechazos: aInt(j['rechazos']),
      );

  @override
  List<Object?> get props => [reporteId, estado, confirmaciones, rechazos];
}
