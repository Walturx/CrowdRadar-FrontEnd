import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:crowdradar/app/fakes/comportamiento_fake.dart';
import 'package:crowdradar/app/fakes/favorito_repository_fake.dart';
import 'package:crowdradar/core/models/categoria_lugar.dart';
import 'package:crowdradar/core/models/lugar_detalle.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/features/lugares/detalle/detalle_lugar_cubit.dart';
import 'package:crowdradar/features/lugares/detalle/detalle_lugar_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/lugar_repo_falso.dart';

const _detalle = LugarDetalle(
  id: 1,
  nombre: 'Parque Kennedy',
  categoria: CategoriaLugar.parque,
  latitud: -12.1219,
  longitud: -77.0297,
  direccion: 'Av. Larco 345, Miraflores',
);
const _favorito = LugarDetalle(
  id: 1,
  nombre: 'Parque Kennedy',
  categoria: CategoriaLugar.parque,
  latitud: -12.1219,
  longitud: -77.0297,
  esFavorito: true,
);

const _errorGenerico =
    'No pudimos obtener la información de este lugar. Inténtalo más tarde.';

DetalleLugarCubit _cubit(
  LugarDetalle detalle, {
  FavoritoRepositoryFake? favoritos,
}) => DetalleLugarCubit(
  RepoLugarFalso(alObtener: (_) async => detalle),
  favoritos ?? FavoritoRepositoryFake(),
  detalle.id,
);

void main() {
  group('cargar', () {
    blocTest<DetalleLugarCubit, DetalleLugarState>(
      'emits Cargando then Cargado with the place',
      build: () => _cubit(_detalle),
      act: (c) => c.cargar(),
      expect: () => const [
        DetalleCargando(),
        DetalleCargado(_detalle, esFavorito: false),
      ],
    );

    blocTest<DetalleLugarCubit, DetalleLugarState>(
      'takes the favorite flag from the detail',
      build: () => _cubit(_favorito),
      act: (c) => c.cargar(),
      expect: () => const [
        DetalleCargando(),
        DetalleCargado(_favorito, esFavorito: true),
      ],
    );

    test('asks the repository for the cubit id', () async {
      final repo = RepoLugarFalso(alObtener: (_) async => _detalle);
      final cubit = DetalleLugarCubit(repo, FavoritoRepositoryFake(), 7);

      await cubit.cargar();

      expect(repo.detallesPedidos, [7]);
      await cubit.close();
    });

    blocTest<DetalleLugarCubit, DetalleLugarState>(
      'a failure is the HU 3.3 message with code and offline flag',
      build: () => DetalleLugarCubit(
        RepoLugarFalso(
          alObtener: (_) async => throw const ApiException(
            status: 500,
            message: 'boom',
            code: 'ERROR_INTERNO',
          ),
        ),
        FavoritoRepositoryFake(),
        1,
      ),
      act: (c) => c.cargar(),
      expect: () => const [
        DetalleCargando(),
        DetalleError(_errorGenerico, codigo: 'ERROR_INTERNO'),
      ],
    );

    blocTest<DetalleLugarCubit, DetalleLugarState>(
      'offline is flagged',
      build: () => DetalleLugarCubit(
        RepoLugarFalso(
          alObtener: (_) async => throw const ApiException.sinConexion(),
        ),
        FavoritoRepositoryFake(),
        1,
      ),
      act: (c) => c.cargar(),
      expect: () => const [
        DetalleCargando(),
        DetalleError(_errorGenerico, esSinConexion: true),
      ],
    );

    blocTest<DetalleLugarCubit, DetalleLugarState>(
      'a 404 has its own message and is not retryable',
      build: () => DetalleLugarCubit(
        RepoLugarFalso(
          alObtener: (_) async => throw const ApiException(
            status: 404,
            message: 'No se pudo obtener la información del lugar.',
            code: 'LUGAR_NO_ENCONTRADO',
          ),
        ),
        FavoritoRepositoryFake(),
        99,
      ),
      act: (c) => c.cargar(),
      expect: () => [
        const DetalleCargando(),
        isA<DetalleError>()
            .having(
              (e) => e.mensaje,
              'mensaje',
              DetalleLugarCubit.mensajeNoEncontrado,
            )
            .having((e) => e.esNoEncontrado, 'esNoEncontrado', true),
      ],
    );

    test('a retry after a failure loads the place', () async {
      var falla = true;
      final cubit = DetalleLugarCubit(
        RepoLugarFalso(
          alObtener: (_) async {
            if (falla) throw const ApiException.sinConexion();
            return _detalle;
          },
        ),
        FavoritoRepositoryFake(),
        1,
      );

      await cubit.cargar();
      expect(cubit.state, isA<DetalleError>());
      falla = false;
      await cubit.cargar();

      expect(cubit.state, const DetalleCargado(_detalle, esFavorito: false));
      await cubit.close();
    });

    test('a second cargar while one is in flight is ignored', () async {
      final espera = Completer<LugarDetalle>();
      final repo = RepoLugarFalso(alObtener: (_) => espera.future);
      final cubit = DetalleLugarCubit(repo, FavoritoRepositoryFake(), 1);

      final primera = cubit.cargar();
      await cubit.cargar();
      espera.complete(_detalle);
      await primera;

      expect(repo.detallesPedidos, hasLength(1));
      await cubit.close();
    });
  });

  group('alternarFavorito', () {
    test('adds the place and flags it while processing', () async {
      final favoritos = FavoritoRepositoryFake();
      final cubit = _cubit(_detalle, favoritos: favoritos);
      await cubit.cargar();
      final estados = <DetalleLugarState>[];
      cubit.stream.listen(estados.add);

      await cubit.alternarFavorito();
      await pumpEventQueue();

      expect(estados, const [
        DetalleCargado(_detalle, esFavorito: false, procesandoFavorito: true),
        DetalleCargado(_detalle, esFavorito: true),
      ]);
      expect((await favoritos.listar()).items.single.lugarId, 1);
      await cubit.close();
    });

    test('toggling twice removes it again', () async {
      final favoritos = FavoritoRepositoryFake();
      final cubit = _cubit(_detalle, favoritos: favoritos);
      await cubit.cargar();

      await cubit.alternarFavorito();
      await cubit.alternarFavorito();

      expect(cubit.state, const DetalleCargado(_detalle, esFavorito: false));
      expect((await favoritos.listar()).estaVacia, isTrue);
      await cubit.close();
    });

    test('a failure keeps the flag and reports the message', () async {
      final cubit = _cubit(
        _detalle,
        favoritos: FavoritoRepositoryFake(
          comportamiento: const ComportamientoFake(
            fallo: ApiException(status: 500, message: 'Servidor caído'),
          ),
        ),
      );
      await cubit.cargar();

      await cubit.alternarFavorito();

      expect(
        cubit.state,
        const DetalleCargado(
          _detalle,
          esFavorito: false,
          errorFavorito: 'Servidor caído',
        ),
      );
      await cubit.close();
    });

    test('a duplicate answer means it already was a favorite', () async {
      final favoritos = FavoritoRepositoryFake();
      await favoritos.agregar(1);
      final cubit = _cubit(_detalle, favoritos: favoritos);
      await cubit.cargar();

      await cubit.alternarFavorito();

      expect(cubit.state, const DetalleCargado(_detalle, esFavorito: true));
      await cubit.close();
    });

    test('is ignored until the place is loaded', () async {
      final favoritos = FavoritoRepositoryFake();
      final cubit = _cubit(_detalle, favoritos: favoritos);

      await cubit.alternarFavorito();

      expect((await favoritos.listar()).estaVacia, isTrue);
      expect(cubit.state, const DetalleCargando());
      await cubit.close();
    });
  });
}
