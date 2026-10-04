import 'package:crowdradar/core/models/validacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/network/respuesta_api.dart';
import 'package:crowdradar/features/validacion/data/validacion_repository.dart';
import 'package:crowdradar/features/validacion/estado/estado_validacion_cubit.dart';
import 'package:crowdradar/features/validacion/estado/estado_validacion_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'json_validacion.dart';

class _MockRepo extends Mock implements ValidacionRepository {}

EstadoReporteValidacion _e(int id, String estado) =>
    EstadoReporteValidacion.fromJson(estadoMioJson(id: id, estado: estado));

Pagina<EstadoReporteValidacion> _pagina(List<EstadoReporteValidacion> items) =>
    Pagina(
      items: items,
      page: 1,
      size: 50,
      total: items.length,
      totalPaginas: 1,
    );

void main() {
  late _MockRepo repo;

  setUp(() => repo = _MockRepo());

  Future<EstadoValidacionCubit> cargado(
    List<EstadoReporteValidacion> items,
  ) async {
    when(
      () => repo.estadoMisReportes(size: any(named: 'size')),
    ).thenAnswer((_) async => _pagina(items));
    final c = EstadoValidacionCubit(repo);
    await c.cargar();
    return c;
  }

  final items = [
    _e(1, 'VALIDADO'),
    _e(2, 'EN_VALIDACION'),
    _e(3, 'RECHAZADO'),
    _e(4, 'SIN_VALIDACIONES'),
  ];

  test('loads the reports with their estado, filter Todos', () async {
    final c = await cargado(items);

    final s = c.state as EstadoValidacionCargado;
    expect(s.filtro, FiltroEstadoValidacion.todos);
    expect(s.visibles.map((e) => e.reporteId), [1, 2, 3, 4]);
    expect(s.estadoDe(2), EstadoValidacion.enValidacion);
    expect(s.estadoDe(99), isNull);
  });

  test('filters client-side by estado', () async {
    final c = await cargado(items);

    c.filtrar(FiltroEstadoValidacion.validados);
    expect(
      (c.state as EstadoValidacionCargado).visibles.map((e) => e.reporteId),
      [1],
    );
    c.filtrar(FiltroEstadoValidacion.enValidacion);
    expect(
      (c.state as EstadoValidacionCargado).visibles.map((e) => e.reporteId),
      [2],
    );
    c.filtrar(FiltroEstadoValidacion.rechazados);
    expect(
      (c.state as EstadoValidacionCargado).visibles.map((e) => e.reporteId),
      [3],
    );
  });

  test('a failure is an Error; a refresh failure keeps the list', () async {
    when(
      () => repo.estadoMisReportes(size: any(named: 'size')),
    ).thenThrow(const ApiException.sinConexion());
    final c = EstadoValidacionCubit(repo);

    await c.cargar();
    expect(c.state, isA<EstadoValidacionError>());

    final bueno = await cargado(items);
    when(
      () => repo.estadoMisReportes(size: any(named: 'size')),
    ).thenThrow(const ApiException.sinConexion());
    await bueno.cargar();
    expect((bueno.state as EstadoValidacionCargado).reportes, hasLength(4));
  });

  test('no reports is a loaded empty list', () async {
    final c = await cargado([]);

    expect((c.state as EstadoValidacionCargado).reportes, isEmpty);
  });
}
