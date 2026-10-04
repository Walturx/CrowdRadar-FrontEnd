import 'dart:math' as math;

import '../map/tipos_mapa.dart';

const double _radioTierraMetros = 6371008.8;

/// Great-circle (haversine) distance in metres.
double distanciaMetros(PuntoGeografico a, PuntoGeografico b) {
  double rad(double grados) => grados * math.pi / 180;
  final dLat = rad(b.latitud - a.latitud);
  final dLng = rad(b.longitud - a.longitud);
  final h =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(a.latitud)) *
          math.cos(rad(b.latitud)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * _radioTierraMetros * math.asin(math.sqrt(h));
}

/// "316 m" under a kilometre, "2.6 km" from there on.
String formatoDistancia(double metros) => metros < 1000
    ? '${metros.round()} m'
    : '${(metros / 1000).toStringAsFixed(1)} km';
