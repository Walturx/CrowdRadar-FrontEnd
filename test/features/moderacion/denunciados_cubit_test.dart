import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:crowdradar/core/models/moderacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/network/respuesta_api.dart';
import 'package:crowdradar/features/moderacion/data/moderacion_repository.dart';
import 'package:crowdradar/features/moderacion/denunciados/denunciados_cubit.dart';
import 'package:crowdradar/features/moderacion/denunciados/denunciados_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'json_moderacion.dart';

class _MockRepo extends Mock implements ModeracionRepository {}

ReporteDenunciado _r(int id) =>
    ReporteDenunciado.fromJson(reporteDenunciadoJson(id: id));

Pagina<ReporteDenunciado> _pagina(
  List<int> ids, {
  int page = 1,
  int totalPaginas = 1,
  int? total,
}) => Pagina(
  items: [for (final i in ids) _r(i)],
  page: page,
  size: DenunciadosCubit.tamanoPagina,
  total: total ?? ids.length,
  totalPaginas: totalPaginas,
);

void main() {
  late _MockRepo repo;

  setUp(() => repo = _MockRepo());

  DenunciadosCubit cubit() => DenunciadosCubit(repo);

  void stub(Pagina<ReporteDenunciado> p, {int page = 1}) => when(
    () => repo.reportesDenunciados(
      page: page,
      size: DenunciadosCubit.tamanoPagina,
    ),
  ).thenAnswer((_) async => p);

  group('cargar (HU 7.1 c1 / c3)', () {
    blocTest<DenunciadosCubit, DenunciadosState>(
      'lists the reports with pending denuncias',
      setUp: () => stub(_pagina([201, 202, 203])),
      build: cubit,
      act: (c) => c.cargar(),
      expect: () => [
        const DenunciadosCargando(),
        isA<DenunciadosCargado>()
            .having((s) => s.reportes.map((r) => r.reporteId), 'ids', [
              201,
              202,
              203,
            ])
            .having((s) => s.total, 'total', 3)
            .having((s) => s.estaVacia, 'estaVacia', false),
      ],
    );

    blocTest<DenunciadosCubit, DenunciadosState>(
      'an empty queue is a loaded empty state, not an error',
      setUp: () => stub(_pagina([])),
      build: cubit,
      act: (c) => c.cargar(),
      expect: () => [
        const DenunciadosCargando(),
        isA<DenunciadosCargado>().having((s) => s.estaVacia, 'estaVacia', true),
      ],
    );

    blocTest<DenunciadosCubit, DenunciadosState>(
      'offline is an error with retry information',
      setUp: () => when(
        () => repo.reportesDenunciados(
          page: any(named: 'page'),
          size: any(named: 'size'),
        ),
      ).thenThrow(const ApiException.sinConexion()),
      build: cubit,
      act: (c) => c.cargar(),
      expect: () => [
        const DenunciadosCargando(),
        isA<DenunciadosError>().having((s) => s.esSinConexion, 'offline', true),
      ],
    );

    test('a second cargar while one is in flight is ignored', () async {
      final respuesta = Completer<Pagina<ReporteDenunciado>>();
      when(
        () => repo.reportesDenunciados(
          page: any(named: 'page'),
          size: any(named: 'size'),
        ),
      ).thenAnswer((_) => respuesta.future);
      final c = cubit();

      final a = c.cargar();
      final b = c.cargar();
      respuesta.complete(_pagina([201]));
      await Future.wait([a, b]);

      verify(
        () => repo.reportesDenunciados(
          page: any(named: 'page'),
          size: any(named: 'size'),
        ),
      ).called(1);
      await c.close();
    });

    test('closing while loading never emits afterwards', () async {
      final respuesta = Completer<Pagina<ReporteDenunciado>>();
      when(
        () => repo.reportesDenunciados(
          page: any(named: 'page'),
          size: any(named: 'size'),
        ),
      ).thenAnswer((_) => respuesta.future);
      final c = cubit();

      final futuro = c.cargar();
      await c.close();
      respuesta.complete(_pagina([201]));

      await expectLater(futuro, completes);
      expect(c.state, const DenunciadosCargando());
    });
  });

  group('refrescar', () {
    test('keeps the list while reloading and replaces it after', () async {
      stub(_pagina([201, 202]));
      final c = cubit();
      await c.cargar();
      stub(_pagina([202]));

      await c.refrescar();

      final s = c.state as DenunciadosCargado;
      expect(s.reportes.map((r) => r.reporteId), [202]);
      await c.close();
    });

    test('a failed refresh keeps the list and reports an aviso', () async {
      stub(_pagina([201]));
      final c = cubit();
      await c.cargar();
      when(
        () => repo.reportesDenunciados(
          page: any(named: 'page'),
          size: any(named: 'size'),
        ),
      ).thenThrow(const ApiException.sinConexion());

      await c.refrescar();

      final s = c.state as DenunciadosCargado;
      expect(s.reportes, hasLength(1));
      expect(s.aviso, ApiException.mensajeSinConexion);
      c.descartarAviso();
      expect((c.state as DenunciadosCargado).aviso, isNull);
      await c.close();
    });
  });

  group('retirar (resolved on the review screen)', () {
    test('removes the report at once and lowers the total', () async {
      stub(_pagina([201, 202, 203]));
      final c = cubit();
      await c.cargar();

      c.retirar(202);

      final s = c.state as DenunciadosCargado;
      expect(s.reportes.map((r) => r.reporteId), [201, 203]);
      expect(s.total, 2);
      await c.close();
    });

    test('removing the last report leaves the empty state', () async {
      stub(_pagina([201]));
      final c = cubit();
      await c.cargar();

      c.retirar(201);

      expect((c.state as DenunciadosCargado).estaVacia, isTrue);
      await c.close();
    });

    test('an unknown id changes nothing', () async {
      stub(_pagina([201]));
      final c = cubit();
      await c.cargar();
      final antes = c.state;

      c.retirar(999);

      expect(c.state, antes);
      await c.close();
    });
  });

  group('cargarMas', () {
    test('appends the next page', () async {
      stub(_pagina([201, 202], total: 3, totalPaginas: 2));
      stub(_pagina([203], page: 2, total: 3, totalPaginas: 2), page: 2);
      final c = cubit();
      await c.cargar();

      await c.cargarMas();

      final s = c.state as DenunciadosCargado;
      expect(s.reportes.map((r) => r.reporteId), [201, 202, 203]);
      expect(s.hayMas, isFalse);
      await c.close();
    });

    test('a failure keeps the loaded reports and reports an aviso', () async {
      stub(_pagina([201], total: 2, totalPaginas: 2));
      when(
        () => repo.reportesDenunciados(
          page: 2,
          size: DenunciadosCubit.tamanoPagina,
        ),
      ).thenThrow(ApiException(status: 500, message: 'Falló', code: 'X'));
      final c = cubit();
      await c.cargar();

      await c.cargarMas();

      final s = c.state as DenunciadosCargado;
      expect(s.reportes, hasLength(1));
      expect(s.aviso, 'Falló');
      expect(s.cargandoMas, isFalse);
      await c.close();
    });
  });
}
