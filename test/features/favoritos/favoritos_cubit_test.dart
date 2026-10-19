import 'dart:async';

import 'package:crowdradar/app/fakes/comportamiento_fake.dart';
import 'package:crowdradar/app/fakes/favorito_repository_fake.dart';
import 'package:crowdradar/core/models/categoria_lugar.dart';
import 'package:crowdradar/core/models/favorito.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/network/respuesta_api.dart';
import 'package:crowdradar/features/favoritos/data/favorito_repository.dart';
import 'package:crowdradar/features/favoritos/lista/favoritos_cubit.dart';
import 'package:crowdradar/features/favoritos/lista/favoritos_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/errores_comunes.dart';

class _MockRepo extends Mock implements FavoritoRepository {}

Favorito _fav(int id, {bool alertas = true}) => Favorito(
  lugarId: id,
  nombre: 'Lugar $id',
  categoria: CategoriaLugar.parque,
  saturacion: NivelSaturacion.moderado,
  alertasActivadas: alertas,
);

ResultadoLista<Favorito> _lista(List<Favorito> items) => ResultadoLista(
  mensaje: items.isEmpty ? 'No tienes lugares favoritos registrados.' : '',
  items: items,
);

FavoritosCargado _cargado(FavoritosCubit c) => c.state as FavoritosCargado;

void main() {
  group('cargar', () {
    test('emits Cargando then Cargado with the favorites', () async {
      final repo = FavoritoRepositoryFake();
      await repo.agregar(1);
      await repo.agregar(2);
      final cubit = FavoritosCubit(repo);
      final estados = <FavoritosState>[];
      cubit.stream.listen(estados.add);

      await cubit.cargar();
      await pumpEventQueue();

      expect(estados.first, const FavoritosCargando());
      expect(_cargado(cubit).favoritos.map((f) => f.lugarId), [2, 1]);
      expect(_cargado(cubit).mensajeVacio, isEmpty);
      await cubit.close();
    });

    test('no favorites carries the HU 8.2 message', () async {
      final cubit = FavoritosCubit(FavoritoRepositoryFake());

      await cubit.cargar();

      expect(_cargado(cubit).favoritos, isEmpty);
      expect(
        _cargado(cubit).mensajeVacio,
        'No tienes lugares favoritos registrados.',
      );
      await cubit.close();
    });

    test(
      'failure emits Error with code and offline flag; retry loads',
      () async {
        final repo = _MockRepo();
        var n = 0;
        when(() => repo.listar()).thenAnswer((_) async {
          if (n++ == 0) throw const ApiException.sinConexion();
          return _lista([_fav(1)]);
        });
        final cubit = FavoritosCubit(repo);

        await cubit.cargar();
        expect(cubit.state, isA<FavoritosError>());
        expect((cubit.state as FavoritosError).esSinConexion, isTrue);

        await cubit.cargar();
        expect(_cargado(cubit).favoritos, [_fav(1)]);
        await cubit.close();
      },
    );

    test('a second load while one is in flight is ignored', () async {
      final repo = _MockRepo();
      final completer = Completer<ResultadoLista<Favorito>>();
      when(() => repo.listar()).thenAnswer((_) => completer.future);
      final cubit = FavoritosCubit(repo);

      final a = cubit.cargar();
      final b = cubit.cargar();
      completer.complete(_lista([_fav(1)]));
      await Future.wait([a, b]);

      verify(() => repo.listar()).called(1);
      await cubit.close();
    });

    test('closing while loading does not emit afterwards', () async {
      final repo = _MockRepo();
      final completer = Completer<ResultadoLista<Favorito>>();
      when(() => repo.listar()).thenAnswer((_) => completer.future);
      final cubit = FavoritosCubit(repo);

      final carga = cubit.cargar();
      await cubit.close();
      completer.complete(_lista([_fav(1)]));

      await expectLater(carga, completes);
    });
  });

  group('refrescar', () {
    test('keeps the list and adds a soft error when it fails', () async {
      final repo = _MockRepo();
      var n = 0;
      when(() => repo.listar()).thenAnswer((_) async {
        if (n++ == 0) return _lista([_fav(1)]);
        throw const ApiException(status: 500, message: 'Servidor caído');
      });
      final cubit = FavoritosCubit(repo);
      await cubit.cargar();

      await cubit.refrescar();

      expect(_cargado(cubit).favoritos, [_fav(1)]);
      expect(_cargado(cubit).error, 'Servidor caído');
      await cubit.close();
    });

    test('without data it behaves like cargar', () async {
      final repo = FavoritoRepositoryFake();
      await repo.agregar(3);
      final cubit = FavoritosCubit(repo);

      await cubit.refrescar();

      expect(_cargado(cubit).favoritos.single.lugarId, 3);
      await cubit.close();
    });
  });

  group('eliminar', () {
    test('removes it, remembers it for undo and keeps the rest', () async {
      final repo = FavoritoRepositoryFake();
      await repo.agregar(1);
      await repo.agregar(2);
      final cubit = FavoritosCubit(repo);
      await cubit.cargar();

      await cubit.eliminar(2);

      expect(_cargado(cubit).favoritos.map((f) => f.lugarId), [1]);
      expect(_cargado(cubit).eliminado?.lugarId, 2);
      expect((await repo.listar()).items.map((f) => f.lugarId), [1]);
      await cubit.close();
    });

    test('removing the last one leaves the empty state message', () async {
      final repo = FavoritoRepositoryFake();
      await repo.agregar(1);
      final cubit = FavoritosCubit(repo);
      await cubit.cargar();

      await cubit.eliminar(1);

      expect(_cargado(cubit).favoritos, isEmpty);
      expect(
        _cargado(cubit).mensajeVacio,
        'No tienes lugares favoritos registrados.',
      );
      await cubit.close();
    });

    test('a 404 means it was already gone: the row disappears', () async {
      final repo = _MockRepo();
      when(() => repo.listar()).thenAnswer((_) async => _lista([_fav(1)]));
      when(() => repo.eliminar(1)).thenThrow(
        const ApiException(
          status: 404,
          message: 'x',
          code: 'FAVORITO_NO_ENCONTRADO',
        ),
      );
      final cubit = FavoritosCubit(repo);
      await cubit.cargar();

      await cubit.eliminar(1);

      expect(_cargado(cubit).favoritos, isEmpty);
      expect(_cargado(cubit).error, isNull);
      await cubit.close();
    });

    test('another failure keeps the row and reports the message', () async {
      final repo = _MockRepo();
      when(() => repo.listar()).thenAnswer((_) async => _lista([_fav(1)]));
      when(
        () => repo.eliminar(1),
      ).thenThrow(const ApiException(status: 500, message: 'Servidor caído'));
      final cubit = FavoritosCubit(repo);
      await cubit.cargar();

      await cubit.eliminar(1);

      expect(_cargado(cubit).favoritos, [_fav(1)]);
      expect(_cargado(cubit).error, 'Servidor caído');
      expect(_cargado(cubit).eliminado, isNull);
      await cubit.close();
    });
  });

  group('deshacerEliminar', () {
    test('adds it back, preserving a disabled alert preference', () async {
      final repo = FavoritoRepositoryFake();
      await repo.agregar(1);
      await repo.configurarAlertas(1, activadas: false);
      final cubit = FavoritosCubit(repo);
      await cubit.cargar();
      await cubit.eliminar(1);

      await cubit.deshacerEliminar();

      final lista = (await repo.listar()).items;
      expect(lista.single.lugarId, 1);
      expect(lista.single.alertasActivadas, isFalse);
      expect(_cargado(cubit).favoritos.single.lugarId, 1);
      expect(_cargado(cubit).eliminado, isNull);
      await cubit.close();
    });

    test('the removed favorite survives another action (R3-801)', () async {
      final repo = FavoritoRepositoryFake();
      await repo.agregar(1);
      await repo.agregar(2);
      final cubit = FavoritosCubit(repo);
      await cubit.cargar();
      await cubit.eliminar(1);

      await cubit.alternarAlertas(2);
      expect(_cargado(cubit).eliminado?.lugarId, 1);
      await cubit.deshacerEliminar();

      expect((await repo.listar()).items.map((f) => f.lugarId), contains(1));
      expect(_cargado(cubit).favoritos.map((f) => f.lugarId), contains(1));
      await cubit.close();
    });

    test('a double tap adds it back once (R3-802)', () async {
      final repo = _MockRepo();
      final agregar = Completer<void>();
      when(() => repo.listar()).thenAnswer((_) async => _lista([_fav(1)]));
      when(() => repo.eliminar(1)).thenAnswer((_) async {});
      when(() => repo.agregar(1)).thenAnswer((_) => agregar.future);
      final cubit = FavoritosCubit(repo);
      await cubit.cargar();
      await cubit.eliminar(1);

      final a = cubit.deshacerEliminar();
      final b = cubit.deshacerEliminar();
      agregar.complete();
      await Future.wait([a, b]);

      verify(() => repo.agregar(1)).called(1);
      await cubit.close();
    });

    test('a refresh in flight does not drop the restored favorite', () async {
      final repo = _MockRepo();
      final lentas = <Completer<ResultadoLista<Favorito>>>[];
      var llamada = 0;
      when(() => repo.listar()).thenAnswer((_) {
        if (llamada++ == 0) return Future.value(_lista([_fav(1)]));
        final c = Completer<ResultadoLista<Favorito>>();
        lentas.add(c);
        return c.future;
      });
      when(() => repo.eliminar(1)).thenAnswer((_) async {});
      when(() => repo.agregar(1)).thenAnswer((_) async {});
      final cubit = FavoritosCubit(repo);
      await cubit.cargar();
      await cubit.eliminar(1);

      final refresco = cubit.refrescar(); // stale: lists without the favorite
      await pumpEventQueue();
      final deshacer = cubit.deshacerEliminar();
      await pumpEventQueue();
      lentas.last.complete(_lista([_fav(1)])); // undo's own reload
      await deshacer;
      lentas.first.complete(_lista(const []));
      await refresco;

      expect(_cargado(cubit).favoritos.map((f) => f.lugarId), [1]);
      await cubit.close();
    });

    test(
      'a failed alerts restore keeps the favorite with the server flag',
      () async {
        final repo = _MockRepo();
        var n = 0;
        when(() => repo.listar()).thenAnswer((_) async {
          if (n++ == 0) return _lista([_fav(1, alertas: false)]);
          return _lista([_fav(1)]);
        });
        when(() => repo.eliminar(1)).thenAnswer((_) async {});
        when(() => repo.agregar(1)).thenAnswer((_) async {});
        when(
          () => repo.configurarAlertas(1, activadas: false),
        ).thenThrow(const ApiException.sinConexion());
        final cubit = FavoritosCubit(repo);
        await cubit.cargar();
        await cubit.eliminar(1);

        await cubit.deshacerEliminar();

        final estado = _cargado(cubit);
        expect(estado.favoritos.single.alertasActivadas, isTrue);
        expect(estado.error, isNotNull);
        await cubit.close();
      },
    );

    test(
      'a failed add keeps the removed favorite so it can be retried',
      () async {
        final repo = _MockRepo();
        when(() => repo.listar()).thenAnswer((_) async => _lista([_fav(1)]));
        when(() => repo.eliminar(1)).thenAnswer((_) async {});
        var intento = 0;
        when(() => repo.agregar(1)).thenAnswer((_) async {
          if (intento++ == 0) throw const ApiException.sinConexion();
        });
        final cubit = FavoritosCubit(repo);
        await cubit.cargar();
        await cubit.eliminar(1);

        await cubit.deshacerEliminar();
        expect(_cargado(cubit).error, isNotNull);
        expect(_cargado(cubit).eliminado?.lugarId, 1);

        await cubit.deshacerEliminar();
        verify(() => repo.agregar(1)).called(2);
        expect(_cargado(cubit).eliminado, isNull);
        await cubit.close();
      },
    );

    test('does nothing when nothing was removed', () async {
      final repo = FavoritoRepositoryFake();
      final cubit = FavoritosCubit(repo);
      await cubit.cargar();

      await cubit.deshacerEliminar();

      expect((await repo.listar()).estaVacia, isTrue);
      await cubit.close();
    });
  });

  group('alertas', () {
    test(
      'alternarAlertas flips one favorite and calls the repository',
      () async {
        final repo = FavoritoRepositoryFake();
        await repo.agregar(1);
        await repo.agregar(2);
        final cubit = FavoritosCubit(repo);
        await cubit.cargar();

        await cubit.alternarAlertas(1);

        final porId = {
          for (final f in _cargado(cubit).favoritos)
            f.lugarId: f.alertasActivadas,
        };
        expect(porId, {1: false, 2: true});
        final servidor = {
          for (final f in (await repo.listar()).items)
            f.lugarId: f.alertasActivadas,
        };
        expect(servidor, {1: false, 2: true});
        await cubit.close();
      },
    );

    test('a failure keeps the previous value and reports it', () async {
      final repo = _MockRepo();
      when(() => repo.listar()).thenAnswer((_) async => _lista([_fav(1)]));
      when(
        () => repo.configurarAlertas(1, activadas: false),
      ).thenThrow(const ApiException(status: 500, message: 'Servidor caído'));
      final cubit = FavoritosCubit(repo);
      await cubit.cargar();

      await cubit.alternarAlertas(1);

      expect(_cargado(cubit).favoritos.single.alertasActivadas, isTrue);
      expect(_cargado(cubit).error, 'Servidor caído');
      expect(_cargado(cubit).procesando, isEmpty);
      await cubit.close();
    });

    test(
      'master switch is on only when every favorite has alerts on',
      () async {
        final repo = FavoritoRepositoryFake();
        await repo.agregar(1);
        await repo.agregar(2);
        final cubit = FavoritosCubit(repo);
        await cubit.cargar();
        expect(_cargado(cubit).todasConAlertas, isTrue);

        await cubit.alternarAlertas(2);

        expect(_cargado(cubit).todasConAlertas, isFalse);
        await cubit.close();
      },
    );

    test('master switch is off for an empty list', () async {
      final cubit = FavoritosCubit(FavoritoRepositoryFake());
      await cubit.cargar();

      expect(_cargado(cubit).todasConAlertas, isFalse);
      await cubit.close();
    });

    test(
      'toggling the master switch issues one call per differing favorite',
      () async {
        final repo = _MockRepo();
        when(() => repo.listar()).thenAnswer(
          (_) async => _lista([_fav(1), _fav(2, alertas: false), _fav(3)]),
        );
        when(
          () =>
              repo.configurarAlertas(any(), activadas: any(named: 'activadas')),
        ).thenAnswer((_) async {});
        final cubit = FavoritosCubit(repo);
        await cubit.cargar();

        // Mixed state: the switch is off, so it turns everything on.
        await cubit.alternarTodasLasAlertas();

        verify(() => repo.configurarAlertas(2, activadas: true)).called(1);
        verifyNever(
          () => repo.configurarAlertas(1, activadas: any(named: 'activadas')),
        );
        expect(_cargado(cubit).todasConAlertas, isTrue);

        // All on: the switch turns everything off.
        await cubit.alternarTodasLasAlertas();

        verify(() => repo.configurarAlertas(1, activadas: false)).called(1);
        verify(() => repo.configurarAlertas(2, activadas: false)).called(1);
        verify(() => repo.configurarAlertas(3, activadas: false)).called(1);
        expect(
          _cargado(cubit).favoritos.every((f) => !f.alertasActivadas),
          isTrue,
        );
        await cubit.close();
      },
    );

    test(
      'a failing master toggle reloads the real state and reports',
      () async {
        final repo = _MockRepo();
        var lecturas = 0;
        when(() => repo.listar()).thenAnswer((_) async {
          lecturas++;
          return _lista([_fav(1), _fav(2)]);
        });
        when(
          () => repo.configurarAlertas(1, activadas: false),
        ).thenAnswer((_) async {});
        when(
          () => repo.configurarAlertas(2, activadas: false),
        ).thenThrow(const ApiException(status: 500, message: 'Servidor caído'));
        final cubit = FavoritosCubit(repo);
        await cubit.cargar();

        await cubit.alternarTodasLasAlertas();

        expect(lecturas, 2, reason: 'reloads to show what the server holds');
        expect(_cargado(cubit).error, 'Servidor caído');
        await cubit.close();
      },
    );
  });

  test('works against a failing fake: load error then success', () async {
    final cubit = FavoritosCubit(
      FavoritoRepositoryFake(
        comportamiento: const ComportamientoFake(
          fallo: ApiException(status: 503, message: 'Caído', code: 'X'),
        ),
      ),
    );

    await cubit.cargar();

    expect(cubit.state, const FavoritosError('Caído', codigo: 'X'));
    await cubit.close();
  });

  group('common errors', () {
    testErroresComunes('a failed load ends as FavoritosError', (caso) async {
      final repo = _MockRepo();
      when(() => repo.listar()).thenThrow(caso.error);
      final cubit = FavoritosCubit(repo);

      await cubit.cargar();

      expect(
        cubit.state,
        FavoritosError(
          caso.mensaje,
          codigo: caso.error.code,
          esSinConexion: caso.esSinConexion,
        ),
      );
      await cubit.close();
    });

    testErroresComunes('a failed removal keeps the row with a soft error', (
      caso,
    ) async {
      final repo = _MockRepo();
      when(() => repo.listar()).thenAnswer((_) async => _lista([_fav(1)]));
      when(() => repo.eliminar(1)).thenThrow(caso.error);
      final cubit = FavoritosCubit(repo);
      await cubit.cargar();

      await cubit.eliminar(1);

      expect(_cargado(cubit).favoritos, [_fav(1)]);
      expect(_cargado(cubit).error, caso.mensaje);
      expect(_cargado(cubit).eliminado, isNull);
      expect(_cargado(cubit).procesando, isEmpty);
      await cubit.close();
    });
  });
}
