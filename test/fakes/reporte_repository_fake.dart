import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/models/reporte_saturacion.dart';
import 'package:crowdradar/core/network/respuesta_api.dart';
import 'package:crowdradar/core/session/session_service.dart';
import 'package:crowdradar/features/reportes/data/reporte_repository.dart';
import 'comportamiento_fake.dart';
import 'datos_fake.dart';
import 'datos_lugares_fake.dart';

/// In-memory reports with the backend rules: 30-minute cooldown per place and
/// no daily cap. A report gives its author points only once it is VALIDADO,
/// which never happens here, so every report of the fake carries 0 (C4).
class ReporteRepositoryFake implements ReporteRepository {
  final ComportamientoFake _comportamiento;
  final DateTime Function() _reloj;

  /// When given, both calls need a signed-in session like the real backend.
  final SessionService? _sesion;

  ReporteRepositoryFake({
    ComportamientoFake comportamiento = const ComportamientoFake(),
    DateTime Function()? reloj,
    SessionService? sesion,
  }) : _comportamiento = comportamiento,
       _sesion = sesion,
       _reloj = reloj ?? DateTime.now;

  static const Duration _espera = Duration(minutes: 30);

  final List<ReporteSaturacion> _mios = [];

  @override
  Future<ReporteCreado> reportar(int lugarId, NivelSaturacion nivel) async {
    await _comportamiento.aplicar();
    _exigirSesion();
    final lugar = lugaresFake.where((l) => l.id == lugarId).firstOrNull;
    if (lugar == null) {
      throw errorFake(404, 'LUGAR_NO_ENCONTRADO', 'El lugar no existe');
    }
    final ahora = _reloj();
    final previo = _mios.where((r) => r.lugarId == lugarId).firstOrNull;
    if (previo != null && ahora.difference(previo.fechaHora!) < _espera) {
      final faltan =
          (_espera - ahora.difference(previo.fechaHora!)).inSeconds / 60;
      final minutos = faltan.ceil();
      throw errorFake(
        422,
        'REPORTE_EN_ESPERA',
        'Ya enviaste un reporte para este lugar; vuelve a intentarlo en '
            '$minutos ${minutos == 1 ? 'minuto' : 'minutos'}.',
      );
    }
    final reporte = ReporteSaturacion(
      id: _mios.length + 1,
      lugarId: lugarId,
      nivel: nivel,
      fechaHora: ahora,
      lugarNombre: lugar.nombre,
      estado: 'ACTIVO',
    );
    _mios.insert(0, reporte);
    return ReporteCreado(reporte: reporte);
  }

  @override
  Future<Pagina<ReporteSaturacion>> listarMios({
    int page = 1,
    int size = 20,
  }) async {
    await _comportamiento.aplicar();
    _exigirSesion();
    return paginar(_mios, page, size);
  }

  void _exigirSesion() {
    if (_sesion != null && _sesion.token == null) {
      throw errorFake(401, 'NO_AUTENTICADO', 'No hay sesión activa');
    }
  }
}
