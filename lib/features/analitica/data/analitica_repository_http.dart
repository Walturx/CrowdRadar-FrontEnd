import '../../../core/models/analitica.dart';
import '../../../core/models/enum_api.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/formato_fecha.dart';
import '../../../core/utils/lectura_json.dart';
import 'analitica_repository.dart';

/// Repository pattern: HTTP implementation of the [AnaliticaRepository] port.
/// Adapts the backend DTOs (`hayDatos`, `recomendaciones`, `diferencias`) into
/// the frozen frontend models.
class AnaliticaRepositoryHttp implements AnaliticaRepository {
  static const String rutaLugares = '/api/lugares';

  final ApiClient _api;

  AnaliticaRepositoryHttp(this._api);

  @override
  Future<SerieSaturacion> historial(
    int lugarId, {
    DateTime? desde,
    DateTime? hasta,
    AgrupacionHistorial? agrupacion,
  }) async {
    final res = await _api.get<SerieSaturacion>(
      '$rutaLugares/$lugarId/historial',
      query: {
        'desde': desde == null ? null : fechaIso(desde),
        'hasta': hasta == null ? null : fechaIso(hasta),
        'agrupacion': agrupacion == null ? null : valorApi(agrupacion),
      },
      mensajeError: 'No se pudo obtener el historial',
      parser: (d) => SerieSaturacion.fromJson(aMapa(d)),
    );
    return res.datos;
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
    final res = await _api.get<ComparacionPeriodos>(
      '$rutaLugares/$lugarId/comparar',
      query: {
        'desdeA': fechaIso(desdeA),
        'hastaA': fechaIso(hastaA),
        'diasA': diasA,
        'desdeB': fechaIso(desdeB),
        'hastaB': fechaIso(hastaB),
        'diasB': diasB,
      },
      mensajeError: 'No se pudo comparar los periodos',
      parser: (d) => ComparacionPeriodos.fromJson(aMapa(d)),
    );
    return res.datos;
  }

  @override
  Future<MejorHorario> mejorHorario(
    int lugarId, {
    String? dias,
    int semanas = 4,
  }) async {
    final res = await _api.get<MejorHorario>(
      '$rutaLugares/$lugarId/mejor-horario',
      query: {'dias': dias, 'semanas': semanas},
      mensajeError: 'No se pudo obtener el mejor horario',
      parser: (d) => MejorHorario.fromJson(aMapa(d)),
    );
    return res.datos;
  }
}
