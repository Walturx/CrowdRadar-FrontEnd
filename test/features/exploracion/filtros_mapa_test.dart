import 'package:crowdradar/core/models/categoria_lugar.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/features/exploracion/data/categoria_resumen.dart';
import 'package:crowdradar/features/exploracion/data/exploracion_repository.dart';
import 'package:crowdradar/features/exploracion/explorar/filtros_mapa.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/comportamiento_fake.dart';
import '../../fakes/exploracion_repository_fake.dart';

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

  testWidgets('shows Todos first, then the server categories with icons', (
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
    expect(find.byKey(const Key('icono-categoria-parque')), findsOneWidget);
    expect(
      tester.widget<Icon>(find.byKey(const Key('icono-categoria-parque'))).icon,
      Icons.park_outlined,
    );
    expect(find.text('Tranquilo'), findsOneWidget);
    expect(find.text('Moderado'), findsOneWidget);
    expect(find.text('Saturado'), findsOneWidget);
    final primero = tester.getTopLeft(
      find.byKey(const Key('chip-categoria-todos')),
    );
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
    bool seleccionado(String texto) => isSemantics(
      isSelected: true,
    ).matches(tester.getSemantics(find.text(texto)), {});
    expect(seleccionado('Parques'), isFalse);

    await tester.tap(find.text('Parques'));
    await tester.pump();

    expect(seleccionado('Parques'), isTrue);
    expect(seleccionado('Mercados'), isFalse);
  });

  group('level chips (design-system §5, D1, D3)', () {
    testWidgets('each level chip carries its meter and its label', (
      tester,
    ) async {
      await abrir(tester, ExploracionRepositoryFake());

      for (final (clave, etiqueta) in [
        ('tranquilo', 'Tranquilo'),
        ('moderado', 'Moderado'),
        ('saturado', 'Saturado'),
      ]) {
        final chip = find.byKey(Key('chip-nivel-$clave'));
        expect(chip, findsOneWidget);
        expect(
          find.descendant(of: chip, matching: find.text(etiqueta)),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: chip,
            matching: find.byKey(const ValueKey('medidor-nivel')),
          ),
          findsOneWidget,
          reason: 'the level chips are the map legend',
        );
      }
      expect(
        find.descendant(
          of: find.byKey(const Key('chip-nivel-todos')),
          matching: find.text('Todos'),
        ),
        findsOneWidget,
        reason: 'D1: the text stays «Todos»',
      );
      expect(find.text('Todos los niveles'), findsNothing);
    });

    testWidgets('«Moderado» fits on one line on a narrow phone', (
      tester,
    ) async {
      await abrir(tester, ExploracionRepositoryFake());
      tester.view.physicalSize = const Size(360, 800);
      await tester.pump();

      final alto = tester.getSize(find.text('Moderado')).height;
      expect(alto, lessThan(24), reason: 'one line, not «Moderad/o»');
    });

    testWidgets('the selected level chip is marked', (tester) async {
      await abrir(tester, ExploracionRepositoryFake());
      bool seleccionado(Key clave) => isSemantics(
        isSelected: true,
      ).matches(tester.getSemantics(find.byKey(clave)), {});

      expect(seleccionado(const Key('chip-nivel-todos')), isTrue);
      expect(seleccionado(const Key('chip-nivel-saturado')), isFalse);

      await tester.tap(find.text('Saturado'));
      await tester.pump();

      expect(seleccionado(const Key('chip-nivel-saturado')), isTrue);
      expect(seleccionado(const Key('chip-nivel-todos')), isFalse);
    });

    testWidgets('every filter chip is at least 44 px tall to touch', (
      tester,
    ) async {
      await abrir(tester, ExploracionRepositoryFake());

      for (final clave in [
        'chip-categoria-todos',
        'chip-categoria-parque',
        'chip-nivel-todos',
        'chip-nivel-tranquilo',
        'chip-nivel-moderado',
        'chip-nivel-saturado',
      ]) {
        final tamano = tester.getSize(find.byKey(Key(clave)));
        expect(tamano.height, greaterThanOrEqualTo(44), reason: clave);
        expect(tamano.width, greaterThanOrEqualTo(44), reason: clave);
      }
    });
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
