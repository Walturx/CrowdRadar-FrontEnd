import '../../core/models/nivel_saturacion.dart';
import '../../core/models/reporte_saturacion.dart';
import '../../core/network/respuesta_api.dart';
import '../../features/reportes/data/reporte_repository.dart';
import 'comportamiento_fake.dart';
import 'datos_fake.dart';

class ReporteRepositoryFake implements ReporteRepository {
  final ComportamientoFake _comportamiento;

  ReporteRepositoryFake({
    ComportamientoFake comportamiento = const ComportamientoFake(),
  }) : _comportamiento = comportamiento;

  static const int _karmaPorReporte = 10;

  final List<ReporteSaturacion> _mios = [];
  int _karma = 100;

  @override
  Future<ReporteCreado> reportar(int lugarId, NivelSaturacion nivel) async {
    await _comportamiento.aplicar();
    if (_mios.any((r) => r.lugarId == lugarId)) {
      throw errorFake(
        422,
        'REPORTE_EN_ESPERA',
        'Ya reportaste este lugar hace poco. Intenta más tarde.',
      );
    }
    final reporte = ReporteSaturacion(
      id: _mios.length + 1,
      lugarId: lugarId,
      nivel: nivel,
      fechaHora: DateTime.now(),
    );
    _mios.insert(0, reporte);
    _karma += _karmaPorReporte;
    return ReporteCreado(
      reporte: reporte,
      puntosGanados: _karmaPorReporte,
      totalKarma: _karma,
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
