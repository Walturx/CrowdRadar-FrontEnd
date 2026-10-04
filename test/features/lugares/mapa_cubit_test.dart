import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:crowdradar/core/map/tipos_mapa.dart';
import 'package:crowdradar/core/models/categoria_lugar.dart';
import 'package:crowdradar/core/models/lugar_resumen.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/network/respuesta_api.dart';
import 'package:crowdradar/features/lugares/mapa/mapa_cubit.dart';
import 'package:crowdradar/features/lugares/mapa/mapa_state.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../fakes/lugar_repo_falso.dart';

const _kennedy = LugarResumen(
  id: 1,
  nombre: 'Parque Kennedy',
  categoria: CategoriaLugar.parque,
  latitud: -12.1219,
  longitud: -77.0297,
  saturacion: NivelSaturacion.tranquilo,
);
const _mercado = LugarResumen(
  id: 2,
  nombre: 'Mercado de Surquillo',
  categoria: CategoriaLugar.mercado,
  latitud: -12.1114,
  longitud: -77.0156,
  saturacion: NivelSaturacion.saturado,
);

const _b1 = LimitesMapa(
  norte: -12.10,
  sur: -12.14,
  este: -77.00,
  oeste: -77.06,
);
const _b2 = LimitesMapa(
  norte: -12.00,
  sur: -12.04,
  este: -77.00,
  oeste: -77.06,
);
const _b3 = LimitesMapa(
  norte: -12.20,
  sur: -12.24,
  este: -77.00,
  oeste: -77.06,
);

void main() {
  group('cargar', () {
    blocTest<MapaCubit, MapaState>(
      'emits Cargando then Cargado with the places and no empty message',
      build: () => MapaCubit(
        RepoLugarFalso(alBuscar: (_) => resultado([_kennedy, _mercado])),
      ),
      act: (c) => c.cargar(_b1),
      expect: () => const [
        MapaCargando(),
        MapaCargado([_kennedy, _mercado]),
      ],
    );

    test('asks the repository for the given bbox and nothing else', () async {
      final repo = RepoLugarFalso(alBuscar: (_) => resultado([_kennedy]));
      final cubit = MapaCubit(repo);

      await cubit.cargar(_b1);
      await cubit.cargar(_b2);

      expect(repo.pedidos.map((p) => p.bbox), [_b1, _b2]);
      await cubit.close();
    });

    blocTest<MapaCubit, MapaState>(
      'an empty zone is Cargado (not Error) with the server message',
      build: () => MapaCubit(
        RepoLugarFalso(
          alBuscar: (_) async => const ResultadoLista(
            mensaje: 'No hay lugares en esta zona.',
            items: [],
          ),
        ),
      ),
      act: (c) => c.cargar(_b1),
      expect: () => const [
        MapaCargando(),
        MapaCargado([], mensajeVacio: 'No hay lugares en esta zona.'),
      ],
    );

    blocTest<MapaCubit, MapaState>(
      'an empty zone without server message falls back to the default text',
      build: () => MapaCubit(RepoLugarFalso(alBuscar: (_) => resultado([]))),
      act: (c) => c.cargar(_b1),
      expect: () => const [
        MapaCargando(),
        MapaCargado([], mensajeVacio: 'No hay lugares en esta zona.'),
      ],
    );

    blocTest<MapaCubit, MapaState>(
      'a failure emits the HU 3.1 error with code and offline flag',
      build: () => MapaCubit(
        RepoLugarFalso(
          alBuscar: (_) async => throw const ApiException(
            status: 500,
            message: 'boom',
            code: 'ERROR_INTERNO',
          ),
        ),
      ),
      act: (c) => c.cargar(_b1),
      expect: () => const [
        MapaCargando(),
        MapaError(
          'Hubo un error al obtener la información geográfica. Revisa tu conexión e inténtalo de nuevo.',
          codigo: 'ERROR_INTERNO',
        ),
      ],
    );

    blocTest<MapaCubit, MapaState>(
      'a network failure is flagged as offline',
      build: () => MapaCubit(
        RepoLugarFalso(
          alBuscar: (_) async => throw const ApiException.sinConexion(),
        ),
      ),
      act: (c) => c.cargar(_b1),
      expect: () => [
        isA<MapaCargando>(),
        isA<MapaError>().having((e) => e.esSinConexion, 'esSinConexion', true),
      ],
    );

    blocTest<MapaCubit, MapaState>(
      'a reload keeps the previous markers while loading',
      build: () =>
          MapaCubit(RepoLugarFalso(alBuscar: (_) => resultado([_kennedy]))),
      act: (c) async {
        await c.cargar(_b1);
        await c.cargar(_b2);
      },
      expect: () => const [
        MapaCargando(),
        MapaCargado([_kennedy]),
        MapaCargando([_kennedy]),
        MapaCargado([_kennedy]),
      ],
    );

    test(
      'a response that arrives after a newer request is discarded',
      () async {
        final lenta = Completer<ResultadoLista<LugarResumen>>();
        final repo = RepoLugarFalso(
          alBuscar: (p) => p.bbox == _b1 ? lenta.future : resultado([_mercado]),
        );
        final cubit = MapaCubit(repo);

        final primera = cubit.cargar(_b1);
        await cubit.cargar(_b2);
        lenta.complete(ResultadoLista(mensaje: '', items: [_kennedy]));
        await primera;

        expect(cubit.state, const MapaCargado([_mercado]));
        await cubit.close();
      },
    );
  });

  group('reintentar', () {
    test('reloads the last bbox after a failure', () async {
      var falla = true;
      final repo = RepoLugarFalso(
        alBuscar: (_) async {
          if (falla) throw const ApiException.sinConexion();
          return ResultadoLista(mensaje: '', items: [_kennedy]);
        },
      );
      final cubit = MapaCubit(repo);

      await cubit.cargar(_b1);
      expect(cubit.state, isA<MapaError>());
      falla = false;
      await cubit.reintentar();

      expect(repo.pedidos.map((p) => p.bbox), [_b1, _b1]);
      expect(cubit.state, const MapaCargado([_kennedy]));
      await cubit.close();
    });

    test('does nothing when the camera never reported bounds', () async {
      final repo = RepoLugarFalso(alBuscar: (_) => resultado([_kennedy]));
      final cubit = MapaCubit(repo);

      await cubit.reintentar();

      expect(repo.pedidos, isEmpty);
      expect(cubit.state, const MapaCargando());
      await cubit.close();
    });
  });

  group('alMoverCamara (debounce 500 ms)', () {
    test('three moves inside the window make one call with the last bbox', () {
      fakeAsync((reloj) {
        final repo = RepoLugarFalso(alBuscar: (_) => resultado([_kennedy]));
        final cubit = MapaCubit(repo);

        cubit.alMoverCamara(_b1);
        reloj.elapse(const Duration(milliseconds: 200));
        cubit.alMoverCamara(_b2);
        reloj.elapse(const Duration(milliseconds: 200));
        cubit.alMoverCamara(_b3);
        reloj.elapse(const Duration(milliseconds: 499));
        expect(repo.pedidos, isEmpty);

        reloj.elapse(const Duration(milliseconds: 1));
        expect(repo.pedidos.map((p) => p.bbox), [_b3]);
        cubit.close();
      });
    });

    test('moves separated by more than the window make two calls', () {
      fakeAsync((reloj) {
        final repo = RepoLugarFalso(alBuscar: (_) => resultado([_kennedy]));
        final cubit = MapaCubit(repo);

        cubit.alMoverCamara(_b1);
        reloj.elapse(const Duration(milliseconds: 600));
        cubit.alMoverCamara(_b2);
        reloj.elapse(const Duration(milliseconds: 600));

        expect(repo.pedidos.map((p) => p.bbox), [_b1, _b2]);
        cubit.close();
      });
    });

    test('closing the cubit cancels a pending call', () {
      fakeAsync((reloj) {
        final repo = RepoLugarFalso(alBuscar: (_) => resultado([_kennedy]));
        final cubit = MapaCubit(repo);

        cubit.alMoverCamara(_b1);
        cubit.close();
        reloj.elapse(const Duration(seconds: 1));

        expect(repo.pedidos, isEmpty);
      });
    });
  });

  group('centro', () {
    test(
      'is unknown until the camera reports and then is the bbox middle',
      () async {
        final cubit = MapaCubit(RepoLugarFalso(alBuscar: (_) => resultado([])));
        expect(cubit.centro, isNull);

        await cubit.cargar(_b1);

        expect(cubit.centro!.latitud, closeTo(-12.12, 1e-9));
        expect(cubit.centro!.longitud, closeTo(-77.03, 1e-9));
        await cubit.cargar(_b2);
        expect(cubit.centro!.latitud, closeTo(-12.02, 1e-9));
        await cubit.close();
      },
    );
  });
}
