/// Windows, limits and day groups shared by the analytics cubits, the HTTP
/// repository and the fake, so the three agree.
abstract final class AnaliticaParametros {
  /// Daily history view ("7 días").
  static const int diasHistorialCorto = 7;

  /// Period comparison window (weekdays against weekends).
  static const int diasVentanaComparacion = 28;
  static const int semanasComparacion = diasVentanaComparacion ~/ 7;

  /// Longest range the history endpoint accepts.
  static const int maxDiasRango = 31;

  /// Best-time recommendations returned.
  static const int topFranjas = 3;

  /// Hours in a day, and the opening-hours range recommendations are drawn
  /// from (`horaCierre` is exclusive).
  static const int horasPorDia = 24;
  static const int horaApertura = 8;
  static const int horaCierre = 22;

  /// Wire values of the `dias` filter.
  static const String laborables = 'LABORABLES';
  static const String finDeSemana = 'FIN_DE_SEMANA';
}
