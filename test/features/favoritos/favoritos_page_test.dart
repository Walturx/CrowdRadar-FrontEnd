import 'package:crowdradar/app/fakes/comportamiento_fake.dart';
import 'package:crowdradar/app/fakes/favorito_repository_fake.dart';
import 'package:crowdradar/core/models/favorito.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/network/respuesta_api.dart';
import 'package:crowdradar/features/favoritos/data/favorito_repository.dart';
import 'package:crowdradar/features/favoritos/lista/favoritos_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/enrutador_falso.dart';

void main() {
  Future<void> abrir(WidgetTester tester, FavoritoRepository repo) async {
    tester.view.physicalSize = const Size(800, 3200);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      RepositoryProvider<FavoritoRepository>.value(
        value: repo,
        child: MaterialApp.router(
          routerConfig: enrutadorDe(
            ruta: '/favoritos',
            inicial: '/favoritos',
            pantalla: const FavoritosPage(),
            otras: const ['/mapa', '/mapa/lugares/1', '/favoritos/alertas'],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<FavoritoRepositoryFake> conFavoritos(List<int> ids) async {
    final repo = FavoritoRepositoryFake();
    for (final id in ids) {
      await repo.agregar(id);
    }
    return repo;
  }

  testWidgets('lists the count and each row with category and level', (
    tester,
  ) async {
    await abrir(tester, await conFavoritos([1, 2, 8]));

    expect(find.text('3 LUGARES GUARDADOS'), findsOneWidget);
    expect(find.text('Parque Kennedy'), findsOneWidget);
    expect(find.text('Mercado de Surquillo'), findsOneWidget);
    expect(find.text('Parque Reducto'), findsOneWidget);
    expect(find.text('🌳'), findsNWidgets(2));
    expect(find.text('Mercado'), findsOneWidget);
    expect(find.text('Tranquilo'), findsOneWidget);
    expect(find.text('Saturado'), findsOneWidget);
    expect(find.text('Sin información'), findsOneWidget);
  });

  testWidgets('a single favorite uses the singular label', (tester) async {
    await abrir(tester, await conFavoritos([1]));

    expect(find.text('1 LUGAR GUARDADO'), findsOneWidget);
  });

  testWidgets('tapping a row opens the place', (tester) async {
    await abrir(tester, await conFavoritos([1]));

    await tester.tap(find.text('Parque Kennedy'));
    await tester.pumpAndSettle();

    expect(find.text('RUTA /mapa/lugares/1'), findsOneWidget);
  });

  testWidgets('re-activating the tab refreshes the list', (tester) async {
    final repo = await conFavoritos([1]);
    final activa = ValueNotifier(false);
    await tester.pumpWidget(
      RepositoryProvider<FavoritoRepository>.value(
        value: repo,
        child: MaterialApp(
          home: ValueListenableBuilder<bool>(
            valueListenable: activa,
            builder: (_, v, _) =>
                TickerMode(enabled: v, child: const FavoritosPage()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Mercado de Surquillo'), findsNothing);

    await repo.agregar(2);
    activa.value = true;
    await tester.pump();
    await tester.pump();

    expect(find.text('Mercado de Surquillo'), findsOneWidget);
    expect(find.text('2 LUGARES GUARDADOS'), findsOneWidget);
  });

  testWidgets('empty state offers the map', (tester) async {
    await abrir(tester, FavoritoRepositoryFake());

    expect(find.text('Sin favoritos aún'), findsOneWidget);
    expect(
      find.text(
        'Marca lugares con el corazón para seguir su saturación de un vistazo.',
      ),
      findsOneWidget,
    );
    expect(find.text('0 LUGARES GUARDADOS'), findsNothing);

    await tester.tap(find.text('Explorar el mapa'));
    await tester.pumpAndSettle();

    expect(find.text('RUTA /mapa'), findsOneWidget);
  });

  testWidgets('an error shows the message and Reintentar reloads', (
    tester,
  ) async {
    await abrir(tester, _Intermitente(await conFavoritos([1])));
    expect(find.text('Servidor caído'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Parque Kennedy'), findsOneWidget);
    expect(find.text('Servidor caído'), findsNothing);
  });

  group('delete', () {
    testWidgets('asks for confirmation; Cancelar keeps the place', (
      tester,
    ) async {
      final repo = await conFavoritos([1, 2]);
      await abrir(tester, repo);

      await tester.tap(find.byKey(const Key('eliminar-1')));
      await tester.pumpAndSettle();

      expect(find.text('¿Eliminar de favoritos?'), findsOneWidget);
      expect(
        find.text('Dejarás de recibir alertas de Parque Kennedy.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Parque Kennedy'), findsOneWidget);
      expect((await repo.listar()).items, hasLength(2));
    });

    testWidgets('Eliminar removes it, updates the count and confirms', (
      tester,
    ) async {
      final repo = await conFavoritos([1, 2]);
      await abrir(tester, repo);

      await tester.tap(find.byKey(const Key('eliminar-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(find.text('Parque Kennedy'), findsNothing);
      expect(find.text('1 LUGAR GUARDADO'), findsOneWidget);
      expect(
        find.text('Se eliminó el lugar de tus favoritos.'),
        findsOneWidget,
      );
      expect((await repo.listar()).items.single.lugarId, 2);
    });

    testWidgets('Deshacer in the toast brings the place back', (tester) async {
      final repo = await conFavoritos([1, 2]);
      await abrir(tester, repo);
      await tester.tap(find.byKey(const Key('eliminar-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();

      expect(find.text('Parque Kennedy'), findsOneWidget);
      expect(find.text('2 LUGARES GUARDADOS'), findsOneWidget);
      expect((await repo.listar()).items, hasLength(2));
    });

    testWidgets('removing the last one shows the empty state', (tester) async {
      await abrir(tester, await conFavoritos([1]));

      await tester.tap(find.byKey(const Key('eliminar-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(find.text('Sin favoritos aún'), findsOneWidget);
    });
  });

  group('alerts', () {
    testWidgets('the master switch turns every favorite off and on', (
      tester,
    ) async {
      final repo = await conFavoritos([1, 2]);
      await abrir(tester, repo);
      expect(find.text('Alertas de cambios'), findsOneWidget);
      expect(find.text('Avísame cuando cambie la saturación'), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
      expect(
        (await repo.listar()).items.every((f) => !f.alertasActivadas),
        isTrue,
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
      expect(
        (await repo.listar()).items.every((f) => f.alertasActivadas),
        isTrue,
      );
    });

    testWidgets('the bell of a row toggles only that favorite', (tester) async {
      final repo = await conFavoritos([1, 2]);
      await abrir(tester, repo);

      await tester.tap(find.byKey(const Key('alertas-1')));
      await tester.pumpAndSettle();

      final porId = {
        for (final f in (await repo.listar()).items)
          f.lugarId: f.alertasActivadas,
      };
      expect(porId, {1: false, 2: true});
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    });

    testWidgets('links to the alerts list', (tester) async {
      await abrir(tester, await conFavoritos([1]));

      await tester.tap(find.byKey(const Key('ir-alertas')));
      await tester.pumpAndSettle();

      expect(find.text('RUTA /favoritos/alertas'), findsOneWidget);
    });
  });
}

/// Fails the first listing, then delegates to [_base].
class _Intermitente extends FavoritoRepositoryFake {
  final FavoritoRepositoryFake _base;
  var _fallo = true;

  _Intermitente(this._base)
    : super(
        comportamiento: const ComportamientoFake(
          fallo: ApiException(status: 500, message: 'Servidor caído'),
        ),
      );

  @override
  Future<ResultadoLista<Favorito>> listar() {
    if (_fallo) {
      _fallo = false;
      return super.listar();
    }
    return _base.listar();
  }
}
