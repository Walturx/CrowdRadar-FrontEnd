/// Relative time in Spanish: "ahora", "hace 5 min", "hace 3 h", "hace 2 d".
String haceCuanto(DateTime fecha, {DateTime? ahora}) {
  final diferencia = (ahora ?? DateTime.now()).difference(fecha);
  if (diferencia.inMinutes < 1) return 'ahora';
  if (diferencia.inHours < 1) return 'hace ${diferencia.inMinutes} min';
  if (diferencia.inDays < 1) return 'hace ${diferencia.inHours} h';
  return 'hace ${diferencia.inDays} d';
}

/// `YYYY-MM-DD` of the local calendar date (wire format of the analytics ranges).
String fechaIso(DateTime fecha) =>
    '${fecha.year.toString().padLeft(4, '0')}-'
    '${fecha.month.toString().padLeft(2, '0')}-'
    '${fecha.day.toString().padLeft(2, '0')}';
