import 'package:flutter/material.dart';

import '../../core/map/tipos_mapa.dart';
import '../../core/models/categoria_lugar.dart';
import '../../core/utils/distancia.dart';

/// Spanish label of a place category; unknown categories read as "Lugar".
String etiquetaCategoria(CategoriaLugar? categoria) => switch (categoria) {
  CategoriaLugar.parque => 'Parque',
  CategoriaLugar.centroComercial => 'Centro comercial',
  CategoriaLugar.mercado => 'Mercado',
  CategoriaLugar.transporte => 'Transporte',
  CategoriaLugar.plaza => 'Plaza',
  CategoriaLugar.playa => 'Playa',
  null => 'Lugar',
};

/// Outlined Material icon of a place category (design-system §6, no emoji);
/// unknown categories read as a generic place.
IconData iconoCategoria(CategoriaLugar? categoria) => switch (categoria) {
  CategoriaLugar.parque => Icons.park_outlined,
  CategoriaLugar.centroComercial => Icons.shopping_bag_outlined,
  CategoriaLugar.mercado => Icons.storefront_outlined,
  CategoriaLugar.transporte => Icons.directions_bus_outlined,
  CategoriaLugar.plaza => Icons.account_balance_outlined,
  CategoriaLugar.playa => Icons.beach_access_outlined,
  null => Icons.place_outlined,
};

/// "Parque · 315 m": the category, plus the distance from [centro] when known.
String subtituloLugar(
  CategoriaLugar? categoria,
  double latitud,
  double longitud,
  PuntoGeografico? centro,
) {
  final etiqueta = etiquetaCategoria(categoria);
  if (centro == null) return etiqueta;
  final metros = distanciaMetros(centro, PuntoGeografico(latitud, longitud));
  return '$etiqueta · ${formatoDistancia(metros)}';
}
