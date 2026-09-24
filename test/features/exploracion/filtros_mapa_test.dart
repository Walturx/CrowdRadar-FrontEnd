import 'package:crowdradar/app/fakes/comportamiento_fake.dart';
import 'package:crowdradar/app/fakes/exploracion_repository_fake.dart';
import 'package:crowdradar/core/models/categoria_lugar.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/features/exploracion/data/categoria_resumen.dart';
import 'package:crowdradar/features/exploracion/data/exploracion_repository.dart';
import 'package:crowdradar/features/exploracion/explorar/filtros_mapa.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Cambio = ({CategoriaLugar? categoria, NivelSaturacion? nivel});

void main() {
  final cambios = <_Cambio>[];

  Future<void> abrir(WidgetTester tester, ExploracionRepository repo) async {
    cambios.clear();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 800);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RepositoryProvider<ExploracionRepository>.value(
        value: repo,
        child: MaterialApp(
          home: Scaffold(
            body: FiltrosMapa(
              alCambiar: (categoria, nivel) =>
                  cambios.add((categoria: categoria, nivel: nivel)),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('shows Todos first, then the server categories with emoji', (
    tester,
  ) async {
    await abrir(tester, ExploracionRepositoryFake());

    expect(find.text('Todos'), findsNWidgets(2), reason: 'category and level');
    for (final etiqueta in [
      'Parques',
      'Centros comerciales',
      'Mercados',
      'Transporte',
      'Plazas',
      'Playas',
    ]) {
      expect(find.text(etiqueta), findsOneWidget);
    }
    expect(find.text('🌳'), findsOneWidget);
    expect(find.text('Tranquilo'), findsOneWidget);
    expect(find.text('Moderado'), findsOneWidget);
    expect(find.text('Saturado'), findsOneWidget);
    final primero = tester.getTopLeft(find.byKey(const Key('chip-categoria-todos')));
    final segundo = tester.getTopLeft(find.text('Parques'));
    expect(primero.dx, lessThan(segundo.dx));
  });

  testWidgets('choosing a category reports it; Todos clears it', (
    tester,
  ) async {
    await abrir(tester, ExploracionRepositoryFake());

    await tester.tap(find.text('Mercados'));
    await tester.pump();
    expect(cambios.last, (categoria: CategoriaLugar.mercado, nivel: null));

    await tester.tap(find.text('Parques'));
    await tester.pump();
    expect(cambios.last, (categoria: CategoriaLugar.parque, nivel: null));

    await tester.tap(find.byKey(const Key('chip-categoria-todos')));
    await tester.pump();
    expect(cambios.last, (categoria: null, nivel: null));
    expect(cambios, hasLength(3));
  });

  testWidgets('the level filter combines with the category', (tester) async {
    await abrir(tester, ExploracionRepositoryFake());

    await tester.tap(find.text('Playas'));
    await tester.pump();
    await tester.tap(find.text('Saturado'));
    await tester.pump();

    expect(cambios.last, (
      categoria: CategoriaLugar.playa,
      nivel: NivelSaturacion.saturado,
    ));

    await tester.tap(find.byKey(const Key('nivel-todos')));
    await tester.pump();
    expect(cambios.last, (categoria: CategoriaLugar.playa, nivel: null));
  });

  testWidgets('the selected chip is marked', (tester) async {
    await abrir(tester, ExploracionRepositoryFake());
    ChoiceChip chip(String texto) => tester.widget<ChoiceChip>(
      find.ancestor(of: find.text(texto), matching: find.byType(ChoiceChip)),
    );
    expect(chip('Parques').selected, isFalse);

    await tester.tap(find.text('Parques'));
    await tester.pump();

    expect(chip('Parques').selected, isTrue);
    expect(chip('Mercados').selected, isFalse);
  });

  testWidgets('a failed categories load offers Reintentar', (tester) async {
    final repo = _Intermitente();
    await abrir(tester, repo);
    expect(find.text('No pudimos cargar las categorías'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Parques'), findsOneWidget);
    expect(find.text('No pudimos cargar las categorías'), findsNothing);
  });
}

/// Fails the first categories request, then answers like the fake.
class _Intermitente extends ExploracionRepositoryFake {
  bool _fallo = true;

  @override
  Future<List<CategoriaResumen>> listarCategorias() {
    if (_fallo) {
      _fallo = false;
      return ExploracionRepositoryFake(
        comportamiento: const ComportamientoFake(
          fallo: ApiException.sinConexion(),
        ),
      ).listarCategorias();
    }
    return super.listarCategorias();
  }
}
