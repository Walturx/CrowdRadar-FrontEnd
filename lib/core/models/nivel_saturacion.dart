import 'enum_api.dart';

enum NivelSaturacion {
  tranquilo,
  moderado,
  saturado,
  sinInformacion;

  /// Null or unknown values mean there is no usable information.
  static NivelSaturacion desdeApi(Object? crudo) =>
      enumDesdeApi(values, crudo) ?? sinInformacion;

  /// Average crowding (1 = tranquilo .. 3 = saturado) from which a value counts
  /// as moderado / saturado; the three levels split the 1..3 range in thirds.
  static const double corteModerado = 1.67;
  static const double corteSaturado = 2.34;

  /// Level of an average crowding value; the single place the cutoffs live.
  /// NaN means there is no usable information.
  static NivelSaturacion desdePromedio(double promedio) => promedio.isNaN
      ? sinInformacion
      : promedio < corteModerado
      ? tranquilo
      : promedio < corteSaturado
      ? moderado
      : saturado;
}
