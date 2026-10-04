/// Tolerant readers shared by the model factories.
Map<String, dynamic> aMapa(Object? o) =>
    o is Map<String, dynamic> ? o : const {};

double aDouble(Object? o) => o is num ? o.toDouble() : 0;

int aInt(Object? o) => o is num ? o.toInt() : 0;

DateTime? aFecha(Object? o) => o is String ? DateTime.tryParse(o) : null;

/// Null unless [o] really is a bool (so `"false"` or `0` never count).
bool? aBool(Object? o) => o is bool ? o : null;

String? aTexto(Object? o) => o is String ? o : null;

List<Object?> aLista(Object? o) => o is List ? o : const [];
