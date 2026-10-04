import 'package:equatable/equatable.dart';

import '../utils/lectura_json.dart';
import 'nivel_saturacion.dart';

enum DecisionModeracion { eliminar, desestimar }

class ReporteDenunciado extends Equatable {
  final int reporteId;
  final String lugarNombre;
  final NivelSaturacion nivel;
  final int totalDenuncias;

  const ReporteDenunciado({
    required this.reporteId,
    required this.lugarNombre,
    required this.nivel,
    required this.totalDenuncias,
  });

  factory ReporteDenunciado.fromJson(Map<String, dynamic> j) =>
      ReporteDenunciado(
        reporteId: aInt(j['reporteId']),
        lugarNombre: j['lugarNombre'] as String? ?? '',
        nivel: NivelSaturacion.desdeApi(j['nivel']),
        totalDenuncias: aInt(j['totalDenuncias']),
      );

  @override
  List<Object?> get props => [reporteId, lugarNombre, nivel, totalDenuncias];
}

class UsuarioAdmin extends Equatable {
  final int id;
  final String nombre;
  final String apellido;
  final String email;
  final String status;
  final int puntosKarma;

  const UsuarioAdmin({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.status,
    this.puntosKarma = 0,
  });

  factory UsuarioAdmin.fromJson(Map<String, dynamic> j) => UsuarioAdmin(
    id: aInt(j['id']),
    nombre: j['nombre'] as String? ?? '',
    apellido: j['apellido'] as String? ?? '',
    email: j['email'] as String? ?? '',
    status: j['status'] as String? ?? '',
    puntosKarma: aInt(j['puntosKarma']),
  );

  bool get estaSuspendido => status == 'SUSPENDIDO';

  @override
  List<Object?> get props => [id, nombre, apellido, email, status, puntosKarma];
}
