import 'package:crowdradar/app/fakes/exploracion_repository_fake.dart';
import 'package:crowdradar/core/models/categoria_lugar.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/features/exploracion/data/filtro_exploracion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final repo = ExploracionRepositoryFake();

  test('categoria filter keeps only that category, ordered by name', () async {
    final res = await repo.explorar(
      const FiltroExploracion(categoria: CategoriaLugar.mercado),
    );

    expect(res.items, isNotEmpty);
    expect(
      res.items.every((l) => l.categoria == CategoriaLugar.mercado),
      isTrue,
    );
    final nombres = res.items.map((l) => l.nombre).toList();
    expect(nombres, [...nombres]..sort());
  });

  test('saturacion filter and AND-combination with categoria', () async {
    final solo = await repo.explorar(
      const FiltroExploracion(saturacion: NivelSaturacion.saturado),
    );
    final ambos = await repo.explorar(
      const FiltroExploracion(
        categoria: CategoriaLugar.parque,
        saturacion: NivelSaturacion.saturado,
      ),
    );

    expect(
      solo.items.every((l) => l.saturacion == NivelSaturacion.saturado),
      isTrue,
    );
    expect(ambos.items.length, lessThan(solo.items.length));
    expect(
      ambos.items.every(
        (l) =>
            l.categoria == CategoriaLugar.parque &&
            l.saturacion == NivelSaturacion.saturado,
      ),
      isTrue,
    );
  });

  test('lat/lng filters by radius and orders by distance', () async {
    final res = await repo.explorar(
      const FiltroExploracion(lat: -12.1219, lng: -77.0297, radioKm: 1),
    );

    expect(res.items.first.nombre, 'Parque Kennedy');
    expect(res.items.first.distanciaMetros, lessThan(50));
    final d = res.items.map((l) => l.distanciaMetros!).toList();
    expect(d, [...d]..sort());
    expect(d.every((m) => m <= 1000), isTrue);
    expect(res.items.length, lessThan(45));
  });

  test('lat without lng is a 400', () async {
    await expectLater(
      repo.explorar(const FiltroExploracion(lat: -12)),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 400)),
    );
  });

  test('empty results carry the three HU messages', () async {
    final cat = await repo.explorar(
      const FiltroExploracion(categoria: CategoriaLugar.playa, lat: 0, lng: 0),
    );
    final niv = await repo.explorar(
      const FiltroExploracion(
        saturacion: NivelSaturacion.tranquilo,
        lat: 0,
        lng: 0,
      ),
    );
    final ambos = await repo.explorar(
      const FiltroExploracion(
        categoria: CategoriaLugar.playa,
        saturacion: NivelSaturacion.tranquilo,
        lat: 0,
        lng: 0,
      ),
    );

    expect(cat.items, isEmpty);
    expect(
      cat.mensaje,
      'No hay lugares cercanos disponibles para esa categoría.',
    );
    expect(niv.mensaje, 'No hay lugares cercanos con ese nivel de saturación.');
    expect(
      ambos.mensaje,
      'No hay lugares cercanos que cumplan con los filtros seleccionados.',
    );
  });

  test('listarCategorias returns the 6 categories with totals', () async {
    final cats = await repo.listarCategorias();

    expect(cats.map((c) => c.categoria), CategoriaLugar.values);
    expect(cats.first.etiqueta, 'Parques');
    expect(cats.fold<int>(0, (s, c) => s + c.total), 45);
  });
}
