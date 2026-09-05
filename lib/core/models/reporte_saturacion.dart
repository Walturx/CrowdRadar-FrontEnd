import 'package:equatable/equatable.dart';

import '../utils/lectura_json.dart';
import 'nivel_saturacion.dart';

class ReporteSaturacion extends Equatable {
  final int id;
  final int lugarId;
  final NivelSaturacion nivel;
  final DateTime? fechaHora;

  const ReporteSaturacion({
    required this.id,
    required this.lugarId,
    required this.nivel,
    this.fechaHora,
  });

  factory ReporteSaturacion.fromJson(Map<String, dynamic> j) =>
      ReporteSaturacion(
        id: aInt(j['id']),
        lugarId: aInt(j['lugarId']),
        nivel: NivelSaturacion.desdeApi(j['nivel']),
        fechaHora: aFecha(j['fechaHora']),
      );

  @override
  List<Object?> get props => [id, lugarId, nivel, fechaHora];
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
  List<Object?> get props =>
      [reporte, puntosGanados, totalKarma, motivoSinPuntos];
}
