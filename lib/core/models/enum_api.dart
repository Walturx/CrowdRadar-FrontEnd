/// `centroComercial` -> `CENTRO_COMERCIAL` (wire format of every backend enum).
String valorApi(Enum valor) => valor.name
    .replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]}')
    .toUpperCase();

/// Finds the enum value for a backend string, or null when unknown.
T? enumDesdeApi<T extends Enum>(List<T> valores, Object? crudo) {
  for (final v in valores) {
    if (valorApi(v) == crudo) return v;
  }
  return null;
}
