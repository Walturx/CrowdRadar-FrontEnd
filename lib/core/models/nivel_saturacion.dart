import 'enum_api.dart';

enum NivelSaturacion {
  tranquilo,
  moderado,
  saturado,
  sinInformacion;

  /// Null or unknown values mean there is no usable information.
  static NivelSaturacion desdeApi(Object? crudo) =>
      enumDesdeApi(values, crudo) ?? sinInformacion;
}
