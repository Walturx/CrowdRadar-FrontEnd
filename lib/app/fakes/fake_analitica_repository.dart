import '../../core/models/analitica.dart';
import '../../core/models/nivel_saturacion.dart';
import '../../features/analitica/data/analitica_repository.dart';
import 'comportamiento_fake.dart';
import 'datos_fake.dart';

class FakeAnaliticaRepository implements AnaliticaRepository {
  final ComportamientoFake _comportamiento;

  FakeAnaliticaRepository({
    ComportamientoFake comportamiento = const ComportamientoFake(),
  }) : _comportamiento = comportamiento;

  static const SerieSaturacion _serie = SerieSaturacion(
    puntos: [
      PuntoSerie('08:00', 1.5),
      PuntoSerie('12:00', 2.8),
      PuntoSerie('18:00', 2.2),
    ],
  );
  static const SerieSaturacion _sinDatos = SerieSaturacion(
    sinDatos: true,
    mensaje: 'Aún no hay suficientes datos',
  );

  bool _tieneDatos(int lugarId) => lugaresFake.any((l) => l.id == lugarId);

  @override
  Future<SerieSaturacion> historial(
    int lugarId, {
    DateTime? desde,
    DateTime? hasta,
  }) async {
    await _comportamiento.aplicar();
    return _tieneDatos(lugarId) ? _serie : _sinDatos;
  }

  @override
  Future<ComparacionPeriodos> comparar(
    int lugarId, {
    required DateTime desdeA,
    required DateTime hastaA,
    required DateTime desdeB,
    required DateTime hastaB,
    String? diasA,
    String? diasB,
  }) async {
    await _comportamiento.aplicar();
    return _tieneDatos(lugarId)
        ? const ComparacionPeriodos(_serie, _serie)
        : const ComparacionPeriodos(_sinDatos, _sinDatos);
  }

  @override
  Future<MejorHorario> mejorHorario(
    int lugarId, {
    String? dias,
    int semanas = 4,
  }) async {
    await _comportamiento.aplicar();
    return _tieneDatos(lugarId)
        ? const MejorHorario(
            franjas: [FranjaHoraria(8, 10, NivelSaturacion.tranquilo)],
          )
        : const MejorHorario(
            sinDatos: true,
            mensaje: 'Aún no hay suficientes datos',
          );
  }
}
