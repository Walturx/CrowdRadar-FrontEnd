import 'dart:math' as math;

/// Cheap integer mix (7919 and 104729 are primes, 2654435761 is Knuth's
/// multiplicative-hash constant); only needs to look random, not be secure.
int _hash(int seed, int hora, bool finDeSemana) =>
    ((seed * 7919 + hora * 104729 + (finDeSemana ? 31 : 0)) * 2654435761) %
    1000;

/// Synthetic crowding value (1 = tranquilo .. 3 = saturado) for one hour.
///
/// Pure and deterministic in `(seed, hora, finDeSemana)`: a daily bell curve
/// (weekends peak later and higher) plus seeded noise.
double valorSintetico(int seed, int hora, {bool finDeSemana = false}) {
  final pico = finDeSemana ? 15.0 : 13.0;
  final ancho = finDeSemana ? 5.0 : 4.0;
  final amplitud = finDeSemana ? 1.8 : 1.4;
  final x = (hora - pico) / ancho;
  final ruido = (_hash(seed, hora, finDeSemana) / 1000 - 0.5) * 0.3;
  final valor = (1.0 + amplitud * math.exp(-x * x) + ruido).clamp(1.0, 3.0);
  return (valor * 100).round() / 100;
}

/// Synthetic number of reports behind one hourly value (always positive).
int muestrasSinteticas(int seed, int hora) => 5 + _hash(seed, hora, false) % 12;
