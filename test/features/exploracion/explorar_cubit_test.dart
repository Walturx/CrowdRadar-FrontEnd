import 'dart:async';

import 'package:crowdradar/app/fakes/comportamiento_fake.dart';
import 'package:crowdradar/app/fakes/exploracion_repository_fake.dart';
import 'package:crowdradar/core/models/categoria_lugar.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/features/exploracion/data/categoria_resumen.dart';
import 'package:crowdradar/features/exploracion/data/exploracion_repository.dart';
import 'package:crowdradar/features/exploracion/explorar/explorar_cubit.dart';
import 'package:crowdradar/features/exploracion/explorar/explorar_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements ExploracionRepository {}

ExplorarCargado _cargado(ExplorarCubit c) => c.state as ExplorarCargado;

void main() {
  group('cargarCategorias', () {
    test('emits Cargando then Cargado with the 6 server categories', () async {
      final cubit = ExplorarCubit(ExploracionRepositoryFake());
      final estados = <ExplorarState>[];
      cubit.stream.listen(estados.add);

      await cubit.cargarCategorias();
      await pumpEventQueue();

      expect(estados.first, const ExplorarCargando());
      expect(_cargado(cubit).categorias, hasLength(6));
      expect(_cargado(cubit).categorias.first.etiqueta, 'Parques');
      expect(_cargado(cubit).categoria, isNull);
      expect(_cargado(cubit).saturacion, isNull);
      await cubit.close();
    });

    test('failure emits Error with code and offline flag', () async {
      final cubit = ExplorarCubit(
        ExploracionRepositoryFake(
          comportamiento: const ComportamientoFake(
            fallo: ApiException.sinConexion(),
          ),
        ),
      );

      await cubit.cargarCategorias();

      expect(cubit.state, isA<ExplorarError>());
      expect((cubit.state as ExplorarError).esSinConexion, isTrue);
      await cubit.close();
    });

    test('a retry after an error loads, keeping the chosen filters', () async {
      final repo = _MockRepo();
      var n = 0;
      when(() => repo.listarCategorias()).thenAnswer((_) async {
        if (n++ == 0) throw const ApiException.sinConexion();
        return const [
          CategoriaResumen(
            categoria: CategoriaLugar.parque,
            etiqueta: 'Parques',
            total: 3,
          ),
        ];
      });
      final cubit = ExplorarCubit(repo);
      cubit.seleccionarSaturacion(NivelSaturacion.saturado);
      await cubit.cargarCategorias();
      expect(cubit.state, isA<ExplorarError>());

      await cubit.cargarCategorias();

      expect(_cargado(cubit).categorias, hasLength(1));
      expect(_cargado(cubit).saturacion, NivelSaturacion.saturado);
      await cubit.close();
    });

    test('a second load while one is in flight is ignored', () async {
      final repo = _MockRepo();
      final completer = Completer<List<CategoriaResumen>>();
      when(() => repo.listarCategorias()).thenAnswer((_) => completer.future);
      final cubit = ExplorarCubit(repo);

      final a = cubit.cargarCategorias();
      final b = cubit.cargarCategorias();
      completer.complete(const []);
      await Future.wait([a, b]);

      verify(() => repo.listarCategorias()).called(1);
      await cubit.close();
    });

    test('closing while loading does not emit afterwards', () async {
      final repo = _MockRepo();
      final completer = Completer<List<CategoriaResumen>>();
      when(() => repo.listarCategorias()).thenAnswer((_) => completer.future);
      final cubit = ExplorarCubit(repo);

      final carga = cubit.cargarCategorias();
      await cubit.close();
      completer.complete(const []);

      await expectLater(carga, completes);
    });
  });

  group('filters', () {
    late ExplorarCubit cubit;

    setUp(() async {
      cubit = ExplorarCubit(ExploracionRepositoryFake());
      await cubit.cargarCategorias();
    });

    tearDown(() => cubit.close());

    test('choosing a category and a level updates the loaded state', () {
      cubit.seleccionarCategoria(CategoriaLugar.mercado);
      expect(_cargado(cubit).categoria, CategoriaLugar.mercado);
      expect(_cargado(cubit).saturacion, isNull);

      cubit.seleccionarSaturacion(NivelSaturacion.tranquilo);
      expect(_cargado(cubit).categoria, CategoriaLugar.mercado);
      expect(_cargado(cubit).saturacion, NivelSaturacion.tranquilo);
    });

    test('null clears one filter and leaves the other', () {
      cubit.seleccionarCategoria(CategoriaLugar.parque);
      cubit.seleccionarSaturacion(NivelSaturacion.saturado);

      cubit.seleccionarCategoria(null);

      expect(_cargado(cubit).categoria, isNull);
      expect(_cargado(cubit).saturacion, NivelSaturacion.saturado);
    });

    test('choosing the same value again emits nothing', () async {
      cubit.seleccionarCategoria(CategoriaLugar.parque);
      final estados = <ExplorarState>[];
      cubit.stream.listen(estados.add);

      cubit.seleccionarCategoria(CategoriaLugar.parque);
      await pumpEventQueue();

      expect(estados, isEmpty);
    });
  });
}
