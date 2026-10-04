import '../../core/models/categoria_lugar.dart';

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
