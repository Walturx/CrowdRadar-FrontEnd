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

String emojiCategoria(CategoriaLugar? categoria) => switch (categoria) {
  CategoriaLugar.parque => '🌳',
  CategoriaLugar.centroComercial => '🛍️',
  CategoriaLugar.mercado => '🧺',
  CategoriaLugar.transporte => '🚌',
  CategoriaLugar.plaza => '⛲',
  CategoriaLugar.playa => '🏖️',
  null => '📍',
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
