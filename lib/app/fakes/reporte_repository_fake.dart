import '../../core/models/nivel_saturacion.dart';
import '../../core/models/reporte_saturacion.dart';
import '../../core/network/respuesta_api.dart';
import '../../features/reportes/data/reporte_repository.dart';
import 'comportamiento_fake.dart';
import 'datos_fake.dart';
import 'datos_lugares_fake.dart';
import 'karma_fake.dart';

/// In-memory reports with the backend rules: 30-minute cooldown per place,
/// +10 karma per report and at most 5 awarded reports per (Lima) day.
class ReporteRepositoryFake implements ReporteRepository {
  final ComportamientoFake _comportamiento;
  final KarmaFake _karma;
  final DateTime Function() _reloj;

  ReporteRepositoryFake({
    ComportamientoFake comportamiento = const ComportamientoFake(),
    KarmaFake? karma,
    DateTime Function()? reloj,
  }) : _comportamiento = comportamiento,
       _karma = karma ?? KarmaFake(),
       _reloj = reloj ?? DateTime.now;

  static const int _karmaPorReporte = 10;
  static const int _premiadosPorDia = 5;
  static const Duration _espera = Duration(minutes: 30);

  final List<ReporteSaturacion> _mios = [];

  static DateTime _diaLima(DateTime t) => t
      .toUtc()
      .subtract(const Duration(hours: 5))
      .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);

  @override
  Future<ReporteCreado> reportar(int lugarId, NivelSaturacion nivel) async {
    await _comportamiento.aplicar();
    final lugar = lugaresFake.where((l) => l.id == lugarId).firstOrNull;
    if (lugar == null) {
      throw errorFake(404, 'LUGAR_NO_ENCONTRADO', 'El lugar no existe');
    }
    final ahora = _reloj();
    final previo = _mios.where((r) => r.lugarId == lugarId).firstOrNull;
    if (previo != null && ahora.difference(previo.fechaHora!) < _espera) {
      throw errorFake(
        422,
        'REPORTE_EN_ESPERA',
        'Ya enviaste un reporte para este lugar. Inténtalo más tarde.',
      );
    }
    final hoy = _diaLima(ahora);
    final premiadosHoy = _mios
        .where((r) => r.puntosOtorgados! > 0 && _diaLima(r.fechaHora!) == hoy)
        .length;
    final premiado = premiadosHoy < _premiadosPorDia;
    final puntos = premiado ? _karmaPorReporte : 0;
    final motivo = premiado ? null : 'TOPE_DIARIO';
    final reporte = ReporteSaturacion(
      id: _mios.length + 1,
      lugarId: lugarId,
      nivel: nivel,
      fechaHora: ahora,
      lugarNombre: lugar.nombre,
      puntosOtorgados: puntos,
      motivoSinPuntos: motivo,
      estado: 'ACTIVO',
    );
    _mios.insert(0, reporte);
    _karma.total += puntos;
    return ReporteCreado(
      reporte: reporte,
      puntosGanados: puntos,
      totalKarma: _karma.total,
      motivoSinPuntos: motivo,
    );
  }

  @override
  Future<Pagina<ReporteSaturacion>> listarMios({
    int page = 1,
    int size = 20,
  }) async {
    await _comportamiento.aplicar();
    return paginar(_mios, page, size);
  }
}
