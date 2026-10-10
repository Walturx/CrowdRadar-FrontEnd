import 'package:equatable/equatable.dart';

import '../utils/lectura_json.dart';
import 'enum_api.dart';
import 'nivel_saturacion.dart';
import 'validacion.dart';

/// Admin verdict on a reported report (`POST .../resolucion`).
enum DecisionModeracion {
  mantener,
  eliminar;

  String get valorApi => _valorApi(this);
}

String _valorApi(Enum e) => valorApi(e);

enum EstadoReporteModerado { activo, eliminado }

enum EstadoCuenta { activo, suspendido }

/// Sort of the admin user directory (`orden` query parameter).
enum OrdenUsuarios {
  recientes,
  nombre,
  karma;

  String get valorApi => _valorApi(this);
}

/// Author of a reported report; [email] comes only in the detail.
class AutorModerado extends Equatable {
  final int id;
  final String nombre;
  final String apellido;
  final String? email;

  const AutorModerado({
    required this.id,
    required this.nombre,
    required this.apellido,
    this.email,
  });

  factory AutorModerado.fromJson(Map<String, dynamic> j) => AutorModerado(
    id: aInt(j['id']),
    nombre: aTexto(j['nombre']) ?? '',
    apellido: aTexto(j['apellido']) ?? '',
    email: aTexto(j['email']),
  );

  /// "Carlos M." as in the HU 7.1 mock.
  String get nombreCorto {
    final inicial = apellido.isEmpty ? '' : ' ${apellido[0]}.';
    return '$nombre$inicial'.trim();
  }

  String get nombreCompleto => '$nombre $apellido'.trim();

  @override
  List<Object?> get props => [id, nombre, apellido, email];
}

/// One row of the moderation queue (`GET /api/admin/reportes-denunciados`).
class ReporteDenunciado extends Equatable {
  final int reporteId;
  final LugarReporte lugar;
  final AutorModerado autor;
  final NivelSaturacion nivel;
  final DateTime? fechaHora;

  /// Denuncias still waiting for a decision.
  final int pendientes;
  final DateTime? ultimaDenunciaEn;

  const ReporteDenunciado({
    required this.reporteId,
    required this.lugar,
    required this.autor,
    required this.nivel,
    required this.pendientes,
    this.fechaHora,
    this.ultimaDenunciaEn,
  });

  factory ReporteDenunciado.fromJson(Map<String, dynamic> j) =>
      ReporteDenunciado(
        reporteId: aInt(j['reporteId']),
        lugar: LugarReporte.fromJson(aMapa(j['lugar'])),
        autor: AutorModerado.fromJson(aMapa(j['autor'])),
        nivel: NivelSaturacion.desdeApi(j['nivel']),
        fechaHora: aFecha(j['fechaHora']),
        pendientes: aInt(j['pendientes']),
        ultimaDenunciaEn: aFecha(j['ultimaDenunciaEn']),
      );

  @override
  List<Object?> get props => [
    reporteId,
    lugar,
    autor,
    nivel,
    fechaHora,
    pendientes,
    ultimaDenunciaEn,
  ];
}

class MotivoConteo extends Equatable {
  final MotivoDenuncia motivo;
  final int total;

  const MotivoConteo({required this.motivo, required this.total});

  factory MotivoConteo.fromJson(Map<String, dynamic> j) => MotivoConteo(
    motivo:
        enumDesdeApi(MotivoDenuncia.values, j['motivo']) ?? MotivoDenuncia.otro,
    total: aInt(j['total']),
  );

  @override
  List<Object?> get props => [motivo, total];
}

/// `GET /api/admin/reportes-denunciados/:reporteId`.
class DetalleReporteDenunciado extends Equatable {
  final int reporteId;
  final LugarReporte lugar;
  final AutorModerado autor;
  final NivelSaturacion nivel;
  final EstadoReporteModerado estado;
  final DateTime? fechaHora;
  final int pendientes;
  final List<MotivoConteo> motivos;

  const DetalleReporteDenunciado({
    required this.reporteId,
    required this.lugar,
    required this.autor,
    required this.nivel,
    required this.estado,
    required this.pendientes,
    required this.motivos,
    this.fechaHora,
  });

  factory DetalleReporteDenunciado.fromJson(Map<String, dynamic> j) =>
      DetalleReporteDenunciado(
        reporteId: aInt(j['reporteId']),
        lugar: LugarReporte.fromJson(aMapa(j['lugar'])),
        autor: AutorModerado.fromJson(aMapa(j['autor'])),
        nivel: NivelSaturacion.desdeApi(j['nivel']),
        estado:
            enumDesdeApi(EstadoReporteModerado.values, j['estado']) ??
            EstadoReporteModerado.activo,
        fechaHora: aFecha(j['fechaHora']),
        pendientes: aInt(j['pendientes']),
        motivos: [
          for (final m in aLista(j['motivos'])) MotivoConteo.fromJson(aMapa(m)),
        ],
      );

  @override
  List<Object?> get props => [
    reporteId,
    lugar,
    autor,
    nivel,
    estado,
    fechaHora,
    pendientes,
    motivos,
  ];
}

/// Outcome of a resolution: the new report [estado] and how many denuncias closed.
class ResolucionReporte extends Equatable {
  final int reporteId;
  final EstadoReporteModerado estado;
  final int denunciasResueltas;

  const ResolucionReporte({
    required this.reporteId,
    required this.estado,
    required this.denunciasResueltas,
  });

  factory ResolucionReporte.fromJson(Map<String, dynamic> j) =>
      ResolucionReporte(
        reporteId: aInt(j['reporteId']),
        estado:
            enumDesdeApi(EstadoReporteModerado.values, j['estado']) ??
            EstadoReporteModerado.activo,
        denunciasResueltas: aInt(j['denunciasResueltas']),
      );

  @override
  List<Object?> get props => [reporteId, estado, denunciasResueltas];
}

/// Temporary suspension (also the `201` body of `POST .../suspension`).
class SancionVigente extends Equatable {
  final int id;
  final int usuarioId;
  final int dias;
  final String motivo;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;

  const SancionVigente({
    required this.id,
    required this.usuarioId,
    required this.dias,
    required this.motivo,
    this.fechaInicio,
    this.fechaFin,
  });

  factory SancionVigente.fromJson(Map<String, dynamic> j) => SancionVigente(
    id: aInt(j['id']),
    usuarioId: aInt(j['usuarioId']),
    dias: aInt(j['dias']),
    motivo: aTexto(j['motivo']) ?? '',
    fechaInicio: aFecha(j['fechaInicio']),
    fechaFin: aFecha(j['fechaFin']),
  );

  /// Days left for "faltan N días": a started day counts, 0 once expired.
  int diasRestantes(DateTime ahora) {
    final fin = fechaFin;
    if (fin == null || !fin.isAfter(ahora)) return 0;
    return (fin.difference(ahora).inMinutes / Duration.minutesPerDay).ceil();
  }

  @override
  List<Object?> get props => [
    id,
    usuarioId,
    dias,
    motivo,
    fechaInicio,
    fechaFin,
  ];
}

/// User of the admin directory (`GET /api/admin/usuarios`).
class UsuarioAdmin extends Equatable {
  final int id;
  final String nombre;
  final String apellido;
  final String email;
  final String rol;
  final EstadoCuenta status;
  final int puntosKarma;
  final SancionVigente? sancionVigente;

  const UsuarioAdmin({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    this.rol = 'USUARIO',
    this.status = EstadoCuenta.activo,
    this.puntosKarma = 0,
    this.sancionVigente,
  });

  factory UsuarioAdmin.fromJson(Map<String, dynamic> j) => UsuarioAdmin(
    id: aInt(j['id']),
    nombre: aTexto(j['nombre']) ?? '',
    apellido: aTexto(j['apellido']) ?? '',
    email: aTexto(j['email']) ?? '',
    rol: aTexto(j['rol']) ?? 'USUARIO',
    status: _estadoCuenta(j['status']),
    puntosKarma: aInt(j['puntosKarma']),
    sancionVigente: j['sancionVigente'] is Map<String, dynamic>
        ? SancionVigente.fromJson(aMapa(j['sancionVigente']))
        : null,
  );

  bool get estaSuspendido => status == EstadoCuenta.suspendido;

  bool get esAdmin => rol == 'ADMIN';

  String get nombreCompleto => '$nombre $apellido'.trim();

  @override
  List<Object?> get props => [
    id,
    nombre,
    apellido,
    email,
    rol,
    status,
    puntosKarma,
    sancionVigente,
  ];
}

EstadoCuenta _estadoCuenta(Object? crudo) =>
    enumDesdeApi(EstadoCuenta.values, crudo) ?? EstadoCuenta.activo;

/// `GET /api/admin/usuarios/:id`: the directory row plus report counters.
class DetalleUsuarioAdmin extends UsuarioAdmin {
  final int reportesPublicados;
  final int reportesDenunciados;

  const DetalleUsuarioAdmin({
    required super.id,
    required super.nombre,
    required super.apellido,
    required super.email,
    super.rol,
    super.status,
    super.puntosKarma,
    super.sancionVigente,
    required this.reportesPublicados,
    required this.reportesDenunciados,
  });

  factory DetalleUsuarioAdmin.fromJson(Map<String, dynamic> j) {
    final base = UsuarioAdmin.fromJson(j);
    return DetalleUsuarioAdmin(
      id: base.id,
      nombre: base.nombre,
      apellido: base.apellido,
      email: base.email,
      rol: base.rol,
      status: base.status,
      puntosKarma: base.puntosKarma,
      sancionVigente: base.sancionVigente,
      reportesPublicados: aInt(j['reportesPublicados']),
      reportesDenunciados: aInt(j['reportesDenunciados']),
    );
  }

  @override
  List<Object?> get props => [
    ...super.props,
    reportesPublicados,
    reportesDenunciados,
  ];
}
