import 'package:crowdradar/core/network/respuesta_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pagina', () {
    test('parses the paginated envelope', () {
      final p = Pagina<int>.fromJson(
        {
          'items': [1, 2],
          'page': 1,
          'size': 20,
          'total': 2,
          'totalPaginas': 1,
        },
        (o) => o as int,
      );

      expect(p.items, [1, 2]);
      expect(p.page, 1);
      expect(p.total, 2);
      expect(p.hayMas, false);
    });

    test('hayMas is true while pages remain; missing data yields empty', () {
      final p = Pagina<int>.fromJson(
        {'items': [1], 'page': 1, 'size': 1, 'total': 3, 'totalPaginas': 3},
        (o) => o as int,
      );
      expect(p.hayMas, true);

      final vacia = Pagina<int>.fromJson(null, (o) => o as int);
      expect(vacia.items, isEmpty);
      expect(vacia.hayMas, false);
    });
  });

  group('ResultadoLista', () {
    test('keeps the explanatory message of an empty list', () {
      final r = ResultadoLista<int>(mensaje: 'No hay lugares', items: const []);

      expect(r.items, isEmpty);
      expect(r.estaVacia, true);
      expect(ResultadoLista<int>(mensaje: '', items: const [1]).estaVacia, false);
    });
  });
}
