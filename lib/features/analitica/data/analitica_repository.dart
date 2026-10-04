import '../../../core/models/analitica.dart';
import '../analitica_parametros.dart';

/// Frozen contract (M4). "No data" is a 200 with `sinDatos`, not an exception.
abstract class AnaliticaRepository {
  /// `GET /api/lugares/:id/historial`.
  Future<SerieSaturacion> historial(
    int lugarId, {
    DateTime? desde,
    DateTime? hasta,
    AgrupacionHistorial? agrupacion,
  });

  /// `GET /api/lugares/:id/comparar`.
  Future<ComparacionPeriodos> comparar(
    int lugarId, {
    required DateTime desdeA,
    required DateTime hastaA,
    required DateTime desdeB,
    required DateTime hastaB,
    String? diasA,
    String? diasB,
  });

  /// `GET /api/lugares/:id/mejor-horario`.
  Future<MejorHorario> mejorHorario(
    int lugarId, {
    String? dias,
    int semanas = AnaliticaParametros.semanasComparacion,
  });
}
