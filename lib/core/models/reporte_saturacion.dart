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
  final String? estado;

  /// Points this report gives its author (`GET /api/reportes/mios`): 10 once
  /// it is VALIDADO, 0 otherwise and in the create response.
  final int puntos;

  const ReporteSaturacion({
    required this.id,
    required this.lugarId,
    required this.nivel,
    this.fechaHora,
    this.lugarNombre,
    this.estado,
    this.puntos = 0,
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
      estado: j['estado'] as String?,
      puntos: aInt(j['puntos']),
    );
  }

  @override
  List<Object?> get props => [
    id,
    lugarId,
    nivel,
    fechaHora,
    lugarNombre,
    estado,
    puntos,
  ];
}

/// Result of `POST /api/reportes` (`data: { reporte, saturacionLugar }`). A
/// report earns nothing when sent: its author gets points once it is VALIDADO.
/// The place's new saturation is read again by the detail, not from here.
class ReporteCreado extends Equatable {
  final ReporteSaturacion reporte;

  const ReporteCreado({required this.reporte});

  factory ReporteCreado.fromJson(Map<String, dynamic> j) =>
      ReporteCreado(reporte: ReporteSaturacion.fromJson(aMapa(j['reporte'])));

  @override
  List<Object?> get props => [reporte];
}
