import '../../core/models/categoria_lugar.dart';
import '../../core/models/moderacion.dart';
import '../../core/models/nivel_saturacion.dart';
import '../../core/models/validacion.dart';
import '../../core/network/respuesta_api.dart';
import '../../core/session/session_service.dart';
import '../../features/moderacion/data/moderacion_repository.dart';
import 'comportamiento_fake.dart';
import 'datos_fake.dart';

/// In-memory moderation with the backend rules: admin only (401 / 403 when a
/// session service is given), 409 on repeated suspensions or reactivations,
/// 422 when suspending an ADMIN or yourself and 400 for a `dias` outside 3/7/30.
class ModeracionRepositoryFake implements ModeracionRepository {
  static const List<int> diasPermitidos = [3, 7, 30];

  final ComportamientoFake _comportamiento;

  /// When given, every call needs a signed-in ADMIN like the real backend.
  final SessionService? _sesion;
  final DateTime Function() _ahora;

  ModeracionRepositoryFake({
    ComportamientoFake comportamiento = const ComportamientoFake(),
    SessionService? sesion,
    DateTime Function()? ahora,
  }) : _comportamiento = comportamiento,
       _sesion = sesion,
       _ahora = ahora ?? DateTime.now;

  late final Map<int, DetalleReporteDenunciado> _denunciados = {
    for (final d in [
      _detalle(201, 'Jockey Plaza', 'Carlos', 'Méndez', {
        MotivoDenuncia.informacionFalsa: 2,
        MotivoDenuncia.contenidoInapropiado: 1,
        MotivoDenuncia.spam: 1,
      }, NivelSaturacion.tranquilo),
      _detalle(202, 'Larcomar', 'Lucía', 'Paredes', {
        MotivoDenuncia.informacionFalsa: 2,
      }, NivelSaturacion.saturado),
      _detalle(203, 'Parque Kennedy', 'Jorge', 'Torres', {
        MotivoDenuncia.spam: 3,
      }, NivelSaturacion.moderado),
    ])
      d.reporteId: d,
  };
  final Set<int> _resueltos = {};

  late final Map<int, UsuarioAdmin> _usuarios = {
    for (final u in [
      const UsuarioAdmin(
        id: 10,
        nombre: 'Admin',
        apellido: 'CrowdRadar',
        email: emailAdminFake,
        rol: 'ADMIN',
        puntosKarma: 0,
      ),
      const UsuarioAdmin(
        id: 11,
        nombre: 'Carlos',
        apellido: 'Méndez',
        email: 'carlos.mendez@correo.pe',
        puntosKarma: 40,
      ),
      _suspendido(12, 'Lucía', 'Paredes', 5),
      _suspendido(13, 'Jorge', 'Torres', 2),
      const UsuarioAdmin(
        id: 14,
        nombre: 'Ana',
        apellido: 'Ruiz',
        email: 'ana.ruiz@correo.pe',
        puntosKarma: 120,
      ),
    ])
      u.id: u,
  };

  DetalleReporteDenunciado _detalle(
    int id,
    String lugar,
    String nombre,
    String apellido,
    Map<MotivoDenuncia, int> motivos,
    NivelSaturacion nivel,
  ) => DetalleReporteDenunciado(
    reporteId: id,
    lugar: LugarReporte(id: id, nombre: lugar, categoria: CategoriaLugar.plaza),
    autor: AutorModerado(
      id: id,
      nombre: nombre,
      apellido: apellido,
      email: '${nombre.toLowerCase()}@correo.pe',
    ),
    nivel: nivel,
    estado: EstadoReporteModerado.activo,
    fechaHora: _ahora().subtract(Duration(hours: id - 200)),
    pendientes: motivos.values.fold(0, (a, b) => a + b),
    motivos: [
      for (final e in motivos.entries)
        MotivoConteo(motivo: e.key, total: e.value),
    ],
  );

  UsuarioAdmin _suspendido(
    int id,
    String nombre,
    String apellido,
    int faltan,
  ) => UsuarioAdmin(
    id: id,
    nombre: nombre,
    apellido: apellido,
    email: '${nombre.toLowerCase()}.${apellido.toLowerCase()}@correo.pe'
        .replaceAll('í', 'i'),
    status: EstadoCuenta.suspendido,
    puntosKarma: 5,
    sancionVigente: SancionVigente(
      id: id,
      usuarioId: id,
      dias: 7,
      motivo: 'Reportes fraudulentos reiterados',
      fechaInicio: _ahora().subtract(Duration(days: 7 - faltan)),
      fechaFin: _ahora().add(Duration(days: faltan)),
    ),
  );

  @override
  Future<Pagina<ReporteDenunciado>> reportesDenunciados({
    int page = 1,
    int size = 20,
  }) async {
    await _entrar();
    return paginar(
      [
        for (final d in _denunciados.values)
          ReporteDenunciado(
            reporteId: d.reporteId,
            lugar: d.lugar,
            autor: d.autor,
            nivel: d.nivel,
            fechaHora: d.fechaHora,
            pendientes: d.pendientes,
            ultimaDenunciaEn: d.fechaHora,
          ),
      ],
      page,
      size,
    );
  }

  @override
  Future<DetalleReporteDenunciado> reporteDenunciado(int reporteId) async {
    await _entrar();
    return _denunciados[reporteId] ?? (throw _reporteNoEncontrado());
  }

  @override
  Future<ResolucionReporte> resolver(
    int reporteId,
    DecisionModeracion decision, {
    String? comentario,
  }) async {
    await _entrar();
    final d = _denunciados.remove(reporteId);
    if (d == null) {
      if (_resueltos.contains(reporteId)) {
        throw errorFake(
          409,
          'SIN_DENUNCIAS_PENDIENTES',
          'El reporte no tiene denuncias pendientes',
        );
      }
      throw _reporteNoEncontrado();
    }
    _resueltos.add(reporteId);
    return ResolucionReporte(
      reporteId: reporteId,
      estado: decision == DecisionModeracion.eliminar
          ? EstadoReporteModerado.eliminado
          : EstadoReporteModerado.activo,
      denunciasResueltas: d.pendientes,
    );
  }

  @override
  Future<Pagina<UsuarioAdmin>> usuarios({
    String? q,
    EstadoCuenta? status,
    OrdenUsuarios? orden,
    int page = 1,
    int size = 20,
  }) async {
    await _entrar();
    final texto = q?.trim().toLowerCase();
    final filtrados = [
      for (final u in _usuarios.values)
        if ((status == null || u.status == status) &&
            (texto == null ||
                '${u.nombre} ${u.apellido} ${u.email}'.toLowerCase().contains(
                  texto,
                )))
          u,
    ];
    switch (orden) {
      case OrdenUsuarios.nombre:
        filtrados.sort((a, b) => a.nombre.compareTo(b.nombre));
      case OrdenUsuarios.karma:
        filtrados.sort((a, b) => b.puntosKarma.compareTo(a.puntosKarma));
      case OrdenUsuarios.recientes || null:
        filtrados.sort((a, b) => b.id.compareTo(a.id));
    }
    return paginar(filtrados, page, size);
  }

  @override
  Future<DetalleUsuarioAdmin> usuario(int usuarioId) async {
    await _entrar();
    final u = _buscar(usuarioId);
    return DetalleUsuarioAdmin(
      id: u.id,
      nombre: u.nombre,
      apellido: u.apellido,
      email: u.email,
      rol: u.rol,
      status: u.status,
      puntosKarma: u.puntosKarma,
      sancionVigente: u.sancionVigente,
      reportesPublicados: 32,
      reportesDenunciados: 5,
    );
  }

  @override
  Future<SancionVigente> suspender(
    int usuarioId, {
    required int dias,
    required String motivo,
  }) async {
    await _entrar();
    final u = _buscar(usuarioId);
    if (u.esAdmin || usuarioId == _sesion?.usuario?.id) {
      throw errorFake(
        422,
        'OPERACION_NO_PERMITIDA',
        'No puedes suspender a este usuario',
      );
    }
    if (u.estaSuspendido) {
      throw errorFake(
        409,
        'USUARIO_YA_SUSPENDIDO',
        'El usuario ya está suspendido',
      );
    }
    if (!diasPermitidos.contains(dias)) {
      throw errorFake(400, 'VALIDACION_FALLIDA', 'Duración no permitida');
    }
    final inicio = _ahora();
    final sancion = SancionVigente(
      id: usuarioId,
      usuarioId: usuarioId,
      dias: dias,
      motivo: motivo.trim(),
      fechaInicio: inicio,
      fechaFin: inicio.add(Duration(days: dias)),
    );
    _guardar(u, EstadoCuenta.suspendido, sancion);
    return sancion;
  }

  @override
  Future<void> reactivar(int usuarioId) async {
    await _entrar();
    final u = _buscar(usuarioId);
    if (!u.estaSuspendido) {
      throw errorFake(
        409,
        'USUARIO_NO_SUSPENDIDO',
        'El usuario no está suspendido',
      );
    }
    _guardar(u, EstadoCuenta.activo, null);
  }

  Future<void> _entrar() async {
    await _comportamiento.aplicar();
    final sesion = _sesion;
    if (sesion == null) return;
    if (sesion.token == null) {
      throw errorFake(401, 'NO_AUTENTICADO', 'No hay sesión activa');
    }
    if (sesion.usuario?.esAdmin != true) {
      throw errorFake(403, 'ACCESO_DENEGADO', 'Acceso denegado');
    }
  }

  UsuarioAdmin _buscar(int id) =>
      _usuarios[id] ??
      (throw errorFake(404, 'USUARIO_NO_ENCONTRADO', 'Usuario no encontrado'));

  void _guardar(UsuarioAdmin u, EstadoCuenta status, SancionVigente? sancion) {
    _usuarios[u.id] = UsuarioAdmin(
      id: u.id,
      nombre: u.nombre,
      apellido: u.apellido,
      email: u.email,
      rol: u.rol,
      status: status,
      puntosKarma: u.puntosKarma,
      sancionVigente: sancion,
    );
  }

  Object _reporteNoEncontrado() =>
      errorFake(404, 'REPORTE_NO_ENCONTRADO', 'Reporte no encontrado');
}
