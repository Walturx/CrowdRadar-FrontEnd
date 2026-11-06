/// A count followed by its noun, singular only when [total] is exactly 1
/// ("1 REPORTE POR REVISAR", "0 USUARIOS", "3 COINCIDENCIAS").
String contador(int total, String singular, String plural) =>
    '$total ${total == 1 ? singular : plural}';
