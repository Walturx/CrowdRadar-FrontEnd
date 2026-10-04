import 'package:crowdradar/core/map/tipos_mapa.dart';
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

  group('subtituloLugar', () {
    const centro = PuntoGeografico(-12.1219, -77.0268);

    test('is the category and the distance from the map centre', () {
      expect(
        subtituloLugar(CategoriaLugar.parque, -12.1219, -77.0297, centro),
        'Parque · 315 m',
      );
    });

    test('is only the category without a map centre', () {
      expect(
        subtituloLugar(CategoriaLugar.mercado, -12.1219, -77.0297, null),
        'Mercado',
      );
    });

    test('an unknown category reads as Lugar', () {
      expect(subtituloLugar(null, -12.1219, -77.0297, null), 'Lugar');
    });
  });

  test('an unknown category falls back to a generic label and pin', () {
    expect(etiquetaCategoria(null), 'Lugar');
    expect(emojiCategoria(null), '📍');
  });
}
