import 'package:crowdradar/core/models/categoria_lugar.dart';
import 'package:crowdradar/features/lugares/categoria_presentacion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every category has its own Spanish label and emoji', () {
    final etiquetas = {
      for (final c in CategoriaLugar.values) c: etiquetaCategoria(c),
    };
    final emojis = {
      for (final c in CategoriaLugar.values) c: emojiCategoria(c),
    };

    expect(etiquetas[CategoriaLugar.parque], 'Parque');
    expect(etiquetas[CategoriaLugar.centroComercial], 'Centro comercial');
    expect(etiquetas.values.toSet(), hasLength(CategoriaLugar.values.length));
    expect(emojis[CategoriaLugar.parque], '🌳');
    expect(emojis.values.toSet(), hasLength(CategoriaLugar.values.length));
  });

  test('an unknown category falls back to a generic label and pin', () {
    expect(etiquetaCategoria(null), 'Lugar');
    expect(emojiCategoria(null), '📍');
  });
}
