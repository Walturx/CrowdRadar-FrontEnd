import '../../core/models/moderacion.dart';
import '../../core/models/nivel_saturacion.dart';
import '../../core/network/respuesta_api.dart';
import '../../features/moderacion/data/moderacion_repository.dart';
import 'datos_fake.dart';

class FakeModeracionRepository implements ModeracionRepository {
  final Map<int, ReporteDenunciado> _denunciados = {
    201: const ReporteDenunciado(
      reporteId: 201,
      lugarNombre: 'Parque Kennedy',
      nivel: NivelSaturacion.saturado,
      totalDenuncias: 3,
    ),
    202: const ReporteDenunciado(
      reporteId: 202,
      lugarNombre: 'Mercado de Surquillo',
      nivel: NivelSaturacion.tranquilo,
      totalDenuncias: 1,
    ),
  };
  final Set<int> _resueltos = {};
  final Map<int, UsuarioAdmin> _usuarios = {
    for (final u in const [
      UsuarioAdmin(
        id: 11,
        nombre: 'Luz',
        apellido: 'Vega',
        email: 'luz@test.com',
        status: 'ACTIVO',
        puntosKarma: 40,
      ),
      UsuarioAdmin(
        id: 12,
        nombre: 'Marco',
        apellido: 'Ruiz',
        email: 'marco@test.com',
        status: 'SUSPENDIDO',
        puntosKarma: 5,
      ),
      UsuarioAdmin(
        id: 13,
        nombre: 'Rosa',
        apellido: 'Gil',
        email: 'rosa@test.com',
        status: 'ACTIVO',
        puntosKarma: 120,
      ),
    ])
      u.id: u,
  };

  @override
  Future<Pagina<ReporteDenunciado>> reportesDenunciados({
    int page = 1,
    int size = 20,
  }) async => paginar(_denunciados.values.toList(), page, size);

  @override
  Future<ReporteDenunciado> reporteDenunciado(int reporteId) async =>
      _denunciados[reporteId] ?? (throw _reporteNoEncontrado());

  @override
  Future<void> resolver(
    int reporteId,
    DecisionModeracion decision, {
    String? comentario,
  }) async {
    if (_denunciados.remove(reporteId) != null) {
      _resueltos.add(reporteId);
    } else if (_resueltos.contains(reporteId)) {
      throw errorFake(
        409,
        'SIN_DENUNCIAS_PENDIENTES',
        'El reporte no tiene denuncias pendientes',
      );
    } else {
      throw _reporteNoEncontrado();
    }
  }

  @override
  Future<Pagina<UsuarioAdmin>> usuarios({
    String? q,
    String? status,
    String? orden,
    int page = 1,
    int size = 20,
  }) async {
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
    return paginar(filtrados, page, size);
  }

  @override
  Future<UsuarioAdmin> usuario(int usuarioId) async =>
      _usuarios[usuarioId] ??
      (throw errorFake(404, 'USUARIO_NO_ENCONTRADO', 'Usuario no encontrado'));

  @override
  Future<void> suspender(
    int usuarioId, {
    required int dias,
    required String motivo,
  }) async {
    final u = await usuario(usuarioId);
    if (u.estaSuspendido) {
      throw errorFake(
        409,
        'USUARIO_YA_SUSPENDIDO',
        'El usuario ya está suspendido',
      );
    }
    _cambiarStatus(u, 'SUSPENDIDO');
  }

  @override
  Future<void> reactivar(int usuarioId) async {
    final u = await usuario(usuarioId);
    if (!u.estaSuspendido) {
      throw errorFake(
        409,
        'USUARIO_NO_SUSPENDIDO',
        'El usuario no está suspendido',
      );
    }
    _cambiarStatus(u, 'ACTIVO');
  }

  void _cambiarStatus(UsuarioAdmin u, String status) {
    _usuarios[u.id] = UsuarioAdmin(
      id: u.id,
      nombre: u.nombre,
      apellido: u.apellido,
      email: u.email,
      status: status,
      puntosKarma: u.puntosKarma,
    );
  }

  Object _reporteNoEncontrado() =>
      errorFake(404, 'REPORTE_NO_ENCONTRADO', 'Reporte no encontrado');
}
