import '../../core/models/analitica.dart';
import '../../core/models/nivel_saturacion.dart';
import '../../core/utils/formato_fecha.dart';
import '../../features/analitica/data/analitica_repository.dart';
import 'comportamiento_fake.dart';
import 'datos_fake.dart';
import 'datos_lugares_fake.dart';
import 'historial_sintetico.dart';

/// In-memory analytics. Known places get a deterministic synthetic history
/// (seeded by the place id) flagged `sintetico`; unknown places have none.
class AnaliticaRepositoryFake implements AnaliticaRepository {
  final ComportamientoFake _comportamiento;

  AnaliticaRepositoryFake({
    ComportamientoFake comportamiento = const ComportamientoFake(),
  }) : _comportamiento = comportamiento;

  static const String _sinHistorial =
      'No existe información histórica disponible para este lugar.';
  static const String _sinComparacion =
      'No existen datos suficientes para realizar la comparación.';
  static const String _sinRecomendacion =
      'No existen datos suficientes para generar la recomendación.';
  static const String _finDeSemana = 'FIN_DE_SEMANA';

  bool _tieneDatos(int lugarId) => lugaresFake.any((l) => l.id == lugarId);

  List<PuntoSerie> _horas(int seed, {bool finDeSemana = false}) => [
    for (var h = 0; h < 24; h++)
      PuntoSerie(
        etiquetaHora(h),
        valorSintetico(seed, h, finDeSemana: finDeSemana),
        muestras: muestrasSinteticas(seed, h),
      ),
  ];

  @override
  Future<SerieSaturacion> historial(
    int lugarId, {
    DateTime? desde,
    DateTime? hasta,
    AgrupacionHistorial? agrupacion,
  }) async {
    await _comportamiento.aplicar();
    if (desde != null &&
        hasta != null &&
        (!hasta.isAfter(desde) || hasta.difference(desde).inDays > 31)) {
      throw errorFake(
        400,
        'RANGO_FECHAS_INVALIDO',
        'El rango de fechas es inválido (máximo 31 días).',
      );
    }
    if (!_tieneDatos(lugarId)) {
      return const SerieSaturacion(sinDatos: true, mensaje: _sinHistorial);
    }
    if (agrupacion != AgrupacionHistorial.dia) {
      return SerieSaturacion(puntos: _horas(lugarId), sintetico: true);
    }
    final fin = hasta ?? DateTime.now();
    final inicio = desde ?? fin.subtract(const Duration(days: 6));
    final dias = DateTime(
      fin.year,
      fin.month,
      fin.day,
    ).difference(DateTime(inicio.year, inicio.month, inicio.day)).inDays;
    return SerieSaturacion(
      puntos: [
        for (var i = 0; i <= dias; i++)
          _punto(lugarId, DateTime(inicio.year, inicio.month, inicio.day + i)),
      ],
      sintetico: true,
    );
  }

  PuntoSerie _punto(int lugarId, DateTime dia) {
    final finDe = dia.weekday >= DateTime.saturday;
    final seed = lugarId * 31 + dia.day + dia.month * 7;
    final horas = [
      for (var h = 8; h < 22; h++) valorSintetico(seed, h, finDeSemana: finDe),
    ];
    final media = horas.reduce((a, b) => a + b) / horas.length;
    return PuntoSerie(
      fechaIso(dia),
      (media * 100).round() / 100,
      muestras: muestrasSinteticas(seed, 12) * 4,
    );
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
    if (!_tieneDatos(lugarId)) {
      return const ComparacionPeriodos(
        SerieSaturacion(sinDatos: true),
        SerieSaturacion(sinDatos: true),
        suficiente: false,
        mensaje: _sinComparacion,
      );
    }
    final a = _horas(lugarId, finDeSemana: diasA == _finDeSemana);
    final b = _horas(lugarId, finDeSemana: diasB == _finDeSemana);
    final diferencias = [
      for (var h = 0; h < 24; h++) DiferenciaHora(h, b[h].valor - a[h].valor),
    ];
    return ComparacionPeriodos(
      SerieSaturacion(puntos: a, sintetico: true),
      SerieSaturacion(puntos: b, sintetico: true),
      diferencias: diferencias,
      resumen: _resumen(diferencias, diasB == _finDeSemana),
    );
  }

  static String _resumen(List<DiferenciaHora> d, bool finDeSemana) {
    final mayor = d.reduce((x, y) => y.diferencia > x.diferencia ? y : x);
    if (mayor.diferencia < 0.3) {
      return 'No hay diferencias notables entre ambos periodos.';
    }
    var ini = mayor.hora;
    var fin = mayor.hora;
    while (ini > 0 && d[ini - 1].diferencia >= 0.3) {
      ini--;
    }
    while (fin < 23 && d[fin + 1].diferencia >= 0.3) {
      fin++;
    }
    final sujeto = finDeSemana
        ? 'Los fines de semana la afluencia sube'
        : 'En el periodo B la afluencia sube';
    return '$sujeto entre ${etiquetaHora(ini)} y ${etiquetaHora((fin + 1) % 24)}.';
  }

  @override
  Future<MejorHorario> mejorHorario(
    int lugarId, {
    String? dias,
    int semanas = 4,
  }) async {
    await _comportamiento.aplicar();
    if (!_tieneDatos(lugarId)) {
      return const MejorHorario(sinDatos: true, mensaje: _sinRecomendacion);
    }
    final candidatas =
        [
          for (var h = 8; h < 22; h++)
            (
              hora: h,
              promedio: valorSintetico(
                lugarId,
                h,
                finDeSemana: dias == _finDeSemana,
              ),
              muestras: muestrasSinteticas(lugarId, h),
            ),
        ]..sort((x, y) {
          final c = x.promedio.compareTo(y.promedio);
          if (c != 0) return c;
          final m = y.muestras.compareTo(x.muestras);
          return m != 0 ? m : x.hora.compareTo(y.hora);
        });
    return MejorHorario(
      franjas: [
        for (final c in candidatas.take(3))
          FranjaHoraria(
            c.hora,
            c.hora + 1,
            c.promedio < 1.67
                ? NivelSaturacion.tranquilo
                : c.promedio < 2.34
                ? NivelSaturacion.moderado
                : NivelSaturacion.saturado,
            promedio: c.promedio,
            muestras: c.muestras,
          ),
      ],
      sintetico: true,
    );
  }
}
