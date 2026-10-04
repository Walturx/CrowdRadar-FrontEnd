import '../../core/models/nivel_saturacion.dart';
import '../../core/models/validacion.dart';
import '../../core/network/respuesta_api.dart';
import '../../features/validacion/data/validacion_repository.dart';
import 'comportamiento_fake.dart';
import 'datos_fake.dart';

class FakeValidacionRepository implements ValidacionRepository {
  final ComportamientoFake _comportamiento;

  FakeValidacionRepository({
    ComportamientoFake comportamiento = const ComportamientoFake(),
  }) : _comportamiento = comportamiento;

  final List<ReportePendiente> _pendientes = [
    ReportePendiente(
      id: 101,
      lugarId: 1,
      lugarNombre: 'Parque Kennedy',
      nivel: NivelSaturacion.saturado,
      fechaHora: DateTime.now(),
      distanciaMetros: 400,
    ),
    ReportePendiente(
      id: 102,
      lugarId: 2,
      lugarNombre: 'Mercado de Surquillo',
      nivel: NivelSaturacion.moderado,
      fechaHora: DateTime.now(),
      distanciaMetros: 1200,
    ),
  ];
  final Map<int, TipoAccionValidacion> _validaciones = {};
  final Set<int> _denunciados = {};

  @override
  Future<Pagina<ReportePendiente>> pendientes({
    double? lat,
    double? lng,
    double radioKm = 5,
    int horas = 3,
    int page = 1,
    int size = 20,
  }) async {
    await _comportamiento.aplicar();
    return paginar(_pendientes, page, size);
  }

  @override
  Future<DetalleReporte> obtenerReporte(int reporteId) async {
    await _comportamiento.aplicar();
    return DetalleReporte(
      reporte: _buscar(reporteId),
      miValidacion: _validaciones[reporteId],
      yaDenunciado: _denunciados.contains(reporteId),
    );
  }

  @override
  Future<void> validar(int reporteId, TipoAccionValidacion accion) async {
    await _comportamiento.aplicar();
    _buscar(reporteId);
    if (_validaciones.containsKey(reporteId)) {
      throw errorFake(409, 'VALIDACION_DUPLICADA', 'Ya validaste este reporte');
    }
    _validaciones[reporteId] = accion;
  }

  @override
  Future<List<EstadoReporteValidacion>> estadoMisReportes() async {
    await _comportamiento.aplicar();
    return const [
      EstadoReporteValidacion(
        reporteId: 1,
        estado: EstadoValidacion.enValidacion,
        confirmaciones: 2,
        rechazos: 1,
      ),
    ];
  }

  @override
  Future<void> denunciar(
    int reporteId,
    MotivoDenuncia motivo, {
    String? detalle,
  }) async {
    await _comportamiento.aplicar();
    _buscar(reporteId);
    if (motivo == MotivoDenuncia.otro && (detalle ?? '').trim().isEmpty) {
      throw errorFake(400, 'VALIDACION_FALLIDA', 'Datos inválidos.');
    }
    if (!_denunciados.add(reporteId)) {
      throw errorFake(409, 'DENUNCIA_DUPLICADA', 'Ya denunciaste este reporte');
    }
  }

  ReportePendiente _buscar(int id) => _pendientes.firstWhere(
    (r) => r.id == id,
    orElse: () =>
        throw errorFake(404, 'REPORTE_NO_ENCONTRADO', 'Reporte no encontrado'),
  );
}
