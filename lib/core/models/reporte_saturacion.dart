import 'package:equatable/equatable.dart';

import '../utils/lectura_json.dart';
import 'nivel_saturacion.dart';

class ReporteSaturacion extends Equatable {
  final int id;
  final int lugarId;
  final NivelSaturacion nivel;
  final DateTime? fechaHora;

  /// Only present in `GET /api/reportes/mios` items (`lugar{id,nombre}`).
  final String? lugarNombre;
  final int? puntosOtorgados;
  final String? motivoSinPuntos;
  final String? estado;

  const ReporteSaturacion({
    required this.id,
    required this.lugarId,
    required this.nivel,
    this.fechaHora,
    this.lugarNombre,
    this.puntosOtorgados,
    this.motivoSinPuntos,
    this.estado,
  });

  /// Accepts both `lugarId` (create response) and `lugar{id,nombre}` (list).
  factory ReporteSaturacion.fromJson(Map<String, dynamic> j) {
    final lugar = aMapa(j['lugar']);
    return ReporteSaturacion(
      id: aInt(j['id']),
      lugarId: aInt(j['lugarId'] ?? lugar['id']),
      nivel: NivelSaturacion.desdeApi(j['nivel']),
      fechaHora: aFecha(j['fechaHora']),
      lugarNombre: lugar['nombre'] as String?,
      puntosOtorgados: j['puntosOtorgados'] is num
          ? aInt(j['puntosOtorgados'])
          : null,
      motivoSinPuntos: j['motivoSinPuntos'] as String?,
      estado: j['estado'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    lugarId,
    nivel,
    fechaHora,
    lugarNombre,
    puntosOtorgados,
    motivoSinPuntos,
    estado,
  ];
}

/// Result of `POST /api/reportes`: the report plus the karma outcome.
class ReporteCreado extends Equatable {
  final ReporteSaturacion reporte;
  final int puntosGanados;
  final int totalKarma;
  final String? motivoSinPuntos;

  const ReporteCreado({
    required this.reporte,
    required this.puntosGanados,
    required this.totalKarma,
    this.motivoSinPuntos,
  });

  factory ReporteCreado.fromJson(Map<String, dynamic> j) {
    final karma = aMapa(j['karma']);
    return ReporteCreado(
      reporte: ReporteSaturacion.fromJson(aMapa(j['reporte'])),
      puntosGanados: aInt(karma['puntosGanados']),
      totalKarma: aInt(karma['total']),
      motivoSinPuntos: karma['motivoSinPuntos'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    reporte,
    puntosGanados,
    totalKarma,
    motivoSinPuntos,
  ];
}
