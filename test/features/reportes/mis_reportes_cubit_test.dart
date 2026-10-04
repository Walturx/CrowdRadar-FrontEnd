import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/models/reporte_saturacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/network/respuesta_api.dart';
import 'package:crowdradar/features/reportes/data/reporte_repository.dart';
import 'package:crowdradar/features/reportes/mis_reportes/mis_reportes_cubit.dart';
import 'package:crowdradar/features/reportes/mis_reportes/mis_reportes_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements ReporteRepository {}

ReporteSaturacion _r(int id) => ReporteSaturacion(
  id: id,
  lugarId: id,
  nivel: NivelSaturacion.moderado,
  lugarNombre: 'Lugar $id',
  puntosOtorgados: 10,
);

Pagina<ReporteSaturacion> _pagina(
  List<int> ids, {
  int page = 1,
  int totalPaginas = 1,
}) => Pagina(
  items: [for (final i in ids) _r(i)],
  page: page,
  size: 2,
  total: ids.length,
  totalPaginas: totalPaginas,
);

void main() {
  late _MockRepo repo;

  setUp(() => repo = _MockRepo());

  MisReportesCubit cubit() => MisReportesCubit(repo, size: 2);

  blocTest<MisReportesCubit, MisReportesState>(
    'cargar emits Cargando then Cargado with the first page',
    setUp: () => when(
      () => repo.listarMios(page: 1, size: 2),
    ).thenAnswer((_) async => _pagina([2, 1], totalPaginas: 2)),
    build: cubit,
    act: (c) => c.cargar(),
    expect: () => [
      const MisReportesCargando(),
      MisReportesCargado([_r(2), _r(1)], hayMas: true),
    ],
  );

  blocTest<MisReportesCubit, MisReportesState>(
    'cargar with no reports emits Vacio',
    setUp: () => when(
      () => repo.listarMios(page: 1, size: 2),
    ).thenAnswer((_) async => _pagina([], totalPaginas: 0)),
    build: cubit,
    act: (c) => c.cargar(),
    expect: () => [const MisReportesCargando(), const MisReportesVacio()],
  );

  blocTest<MisReportesCubit, MisReportesState>(
    'cargar failure emits Error carrying code and offline flag; retry works',
    setUp: () {
      var n = 0;
      when(() => repo.listarMios(page: 1, size: 2)).thenAnswer((_) async {
        if (n++ == 0) throw const ApiException.sinConexion();
        return _pagina([1]);
      });
    },
    build: cubit,
    act: (c) async {
      await c.cargar();
      await c.cargar();
    },
    expect: () => [
      const MisReportesCargando(),
      const MisReportesError(
        ApiException.mensajeSinConexion,
        esSinConexion: true,
      ),
      const MisReportesCargando(),
      MisReportesCargado([_r(1)]),
    ],
  );

  blocTest<MisReportesCubit, MisReportesState>(
    'cargarMas appends the next page and clears hayMas on the last one',
    setUp: () {
      when(
        () => repo.listarMios(page: 1, size: 2),
      ).thenAnswer((_) async => _pagina([3, 2], totalPaginas: 2));
      when(
        () => repo.listarMios(page: 2, size: 2),
      ).thenAnswer((_) async => _pagina([1], page: 2, totalPaginas: 2));
    },
    build: cubit,
    act: (c) async {
      await c.cargar();
      await c.cargarMas();
    },
    skip: 2,
    expect: () => [
      MisReportesCargado([_r(3), _r(2)], hayMas: true, cargandoMas: true),
      MisReportesCargado([_r(3), _r(2), _r(1)]),
    ],
  );

  blocTest<MisReportesCubit, MisReportesState>(
    'cargarMas with no more pages does nothing',
    setUp: () => when(
      () => repo.listarMios(page: 1, size: 2),
    ).thenAnswer((_) async => _pagina([2, 1])),
    build: cubit,
    act: (c) async {
      await c.cargar();
      await c.cargarMas();
    },
    skip: 2,
    expect: () => <MisReportesState>[],
    verify: (_) =>
        verifyNever(() => repo.listarMios(page: 2, size: any(named: 'size'))),
  );

  blocTest<MisReportesCubit, MisReportesState>(
    'a failing cargarMas keeps the list and reports the error',
    setUp: () {
      when(
        () => repo.listarMios(page: 1, size: 2),
      ).thenAnswer((_) async => _pagina([2, 1], totalPaginas: 2));
      when(
        () => repo.listarMios(page: 2, size: 2),
      ).thenThrow(const ApiException(status: 500, message: 'caído'));
    },
    build: cubit,
    act: (c) async {
      await c.cargar();
      await c.cargarMas();
    },
    skip: 3,
    expect: () => [
      MisReportesCargado([_r(2), _r(1)], hayMas: true, errorMas: 'caído'),
    ],
  );

  test('cargarMas while a page is loading is ignored', () async {
    final siguiente = Completer<Pagina<ReporteSaturacion>>();
    when(
      () => repo.listarMios(page: 1, size: 2),
    ).thenAnswer((_) async => _pagina([2, 1], totalPaginas: 3));
    when(
      () => repo.listarMios(page: 2, size: 2),
    ).thenAnswer((_) => siguiente.future);
    final c = cubit();
    await c.cargar();

    final a = c.cargarMas();
    await c.cargarMas();
    siguiente.complete(_pagina([0], page: 2, totalPaginas: 3));
    await a;

    verify(() => repo.listarMios(page: 2, size: 2)).called(1);
  });

  group('refresh, races and pagination edges (R3-604)', () {
    blocTest<MisReportesCubit, MisReportesState>(
      'cargar over a loaded list keeps it visible until the new data arrives',
      setUp: () {
        var n = 0;
        when(
          () => repo.listarMios(page: 1, size: 2),
        ).thenAnswer((_) async => n++ == 0 ? _pagina([2, 1]) : _pagina([3, 2]));
      },
      build: cubit,
      act: (c) async {
        await c.cargar();
        await c.cargar();
      },
      skip: 2,
      expect: () => [
        MisReportesCargado([_r(3), _r(2)]),
      ],
    );

    blocTest<MisReportesCubit, MisReportesState>(
      'a failed refresh keeps the list and reports the error',
      setUp: () {
        var n = 0;
        when(() => repo.listarMios(page: 1, size: 2)).thenAnswer((_) async {
          if (n++ == 0) return _pagina([2, 1]);
          throw const ApiException.sinConexion();
        });
      },
      build: cubit,
      act: (c) async {
        await c.cargar();
        await c.cargar();
      },
      skip: 2,
      expect: () => [
        MisReportesCargado([
          _r(2),
          _r(1),
        ], errorActualizacion: ApiException.mensajeSinConexion),
      ],
    );

    test(
      'a failed refresh during cargarMas does not discard the valid page',
      () async {
        final siguiente = Completer<Pagina<ReporteSaturacion>>();
        var primeras = 0;
        when(() => repo.listarMios(page: 1, size: 2)).thenAnswer((_) async {
          if (primeras++ == 0) return _pagina([2, 1], totalPaginas: 3);
          throw const ApiException.sinConexion();
        });
        when(
          () => repo.listarMios(page: 2, size: 2),
        ).thenAnswer((_) => siguiente.future);
        final c = cubit();
        await c.cargar();

        final mas = c.cargarMas();
        await c.cargar(); // fails
        siguiente.complete(_pagina([0], page: 2, totalPaginas: 3));
        await mas;

        final estado = c.state as MisReportesCargado;
        expect(estado.reportes, [_r(2), _r(1), _r(0)]);
        expect(estado.errorMas, isNull);
      },
    );

    test(
      'a failed refresh reports errorActualizacion, never errorMas',
      () async {
        var n = 0;
        when(() => repo.listarMios(page: 1, size: 2)).thenAnswer((_) async {
          if (n++ == 0) return _pagina([2, 1]);
          throw const ApiException(status: 500, message: 'caído');
        });
        final c = cubit();
        await c.cargar();
        await c.cargar();

        final estado = c.state as MisReportesCargado;
        expect(estado.errorActualizacion, 'caído');
        expect(estado.errorMas, isNull);
      },
    );

    test('cargar during cargarMas is not dropped and wins the race', () async {
      final siguiente = Completer<Pagina<ReporteSaturacion>>();
      var primeras = 0;
      when(() => repo.listarMios(page: 1, size: 2)).thenAnswer(
        (_) async => primeras++ == 0
            ? _pagina([2, 1], totalPaginas: 3)
            : _pagina([9, 8]),
      );
      when(
        () => repo.listarMios(page: 2, size: 2),
      ).thenAnswer((_) => siguiente.future);
      final c = cubit();
      await c.cargar();

      final mas = c.cargarMas();
      await c.cargar();
      siguiente.complete(_pagina([0], page: 2, totalPaginas: 3));
      await mas;

      expect(c.state, MisReportesCargado([_r(9), _r(8)]));
    });

    blocTest<MisReportesCubit, MisReportesState>(
      'cargarMas drops ids that are already in the list',
      setUp: () {
        when(
          () => repo.listarMios(page: 1, size: 2),
        ).thenAnswer((_) async => _pagina([3, 2], totalPaginas: 2));
        when(
          () => repo.listarMios(page: 2, size: 2),
        ).thenAnswer((_) async => _pagina([2, 1], page: 2, totalPaginas: 2));
      },
      build: cubit,
      act: (c) async {
        await c.cargar();
        await c.cargarMas();
      },
      skip: 3,
      expect: () => [
        MisReportesCargado([_r(3), _r(2), _r(1)]),
      ],
    );

    blocTest<MisReportesCubit, MisReportesState>(
      'an empty page stops "Cargar más" even if hayMas is still true',
      setUp: () {
        when(
          () => repo.listarMios(page: 1, size: 2),
        ).thenAnswer((_) async => _pagina([2, 1], totalPaginas: 5));
        when(
          () => repo.listarMios(page: 2, size: 2),
        ).thenAnswer((_) async => _pagina([], page: 2, totalPaginas: 5));
      },
      build: cubit,
      act: (c) async {
        await c.cargar();
        await c.cargarMas();
      },
      skip: 3,
      expect: () => [
        MisReportesCargado([_r(2), _r(1)]),
      ],
    );
  });
}
