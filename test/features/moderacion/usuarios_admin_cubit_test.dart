import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:crowdradar/core/models/moderacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/network/respuesta_api.dart';
import 'package:crowdradar/features/moderacion/data/moderacion_repository.dart';
import 'package:crowdradar/features/moderacion/usuarios/usuarios_admin_cubit.dart';
import 'package:crowdradar/features/moderacion/usuarios/usuarios_admin_state.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'json_moderacion.dart';
import '../../helpers/errores_comunes.dart';

class _MockRepo extends Mock implements ModeracionRepository {}

UsuarioAdmin _u(int id, {bool suspendido = false}) => UsuarioAdmin.fromJson(
  usuarioJson(
    id: id,
    status: suspendido ? 'SUSPENDIDO' : 'ACTIVO',
    sancion: suspendido ? sancionJson() : null,
  ),
);

Pagina<UsuarioAdmin> _pagina(
  List<int> ids, {
  int page = 1,
  int total = 0,
  int totalPaginas = 1,
}) => Pagina(
  items: [for (final i in ids) _u(i)],
  page: page,
  size: 20,
  total: total == 0 ? ids.length : total,
  totalPaginas: totalPaginas,
);

void main() {
  late _MockRepo repo;

  setUpAll(() {
    registerFallbackValue(EstadoCuenta.activo);
    registerFallbackValue(OrdenUsuarios.recientes);
  });

  setUp(() => repo = _MockRepo());

  UsuariosAdminCubit cubit({Duration espera = Duration.zero}) =>
      UsuariosAdminCubit(repo, espera: espera);

  void stub(Pagina<UsuarioAdmin> pagina) => when(
    () => repo.usuarios(
      q: any(named: 'q'),
      status: any(named: 'status'),
      orden: any(named: 'orden'),
      page: any(named: 'page'),
      size: any(named: 'size'),
    ),
  ).thenAnswer((_) async => pagina);

  Future<UsuariosAdminCubit> cargado(Pagina<UsuarioAdmin> pagina) async {
    stub(pagina);
    final c = cubit();
    await c.cargar();
    return c;
  }

  group('cargar', () {
    blocTest<UsuariosAdminCubit, UsuariosAdminState>(
      'loads the first page ordered by recientes with no filters',
      setUp: () => stub(_pagina([1, 2], total: 2)),
      build: cubit,
      act: (c) => c.cargar(),
      expect: () => [
        const UsuariosAdminCargando(),
        isA<UsuariosAdminCargado>()
            .having((s) => s.usuarios.map((u) => u.id), 'ids', [1, 2])
            .having((s) => s.total, 'total', 2)
            .having((s) => s.hayMas, 'hayMas', false),
      ],
      verify: (_) => verify(
        () => repo.usuarios(
          q: null,
          status: null,
          orden: OrdenUsuarios.recientes,
          page: 1,
          size: UsuariosAdminCubit.tamanoPagina,
        ),
      ).called(1),
    );

    blocTest<UsuariosAdminCubit, UsuariosAdminState>(
      'an offline failure is an error with retry information',
      setUp: () => when(
        () => repo.usuarios(
          q: any(named: 'q'),
          status: any(named: 'status'),
          orden: any(named: 'orden'),
          page: any(named: 'page'),
          size: any(named: 'size'),
        ),
      ).thenThrow(ApiException.sinConexion()),
      build: cubit,
      act: (c) => c.cargar(),
      expect: () => [
        const UsuariosAdminCargando(),
        isA<UsuariosAdminError>().having(
          (s) => s.esSinConexion,
          'offline',
          true,
        ),
      ],
    );

    blocTest<UsuariosAdminCubit, UsuariosAdminState>(
      '403 ACCESO_DENEGADO is an error carrying the code',
      setUp: () =>
          when(
            () => repo.usuarios(
              q: any(named: 'q'),
              status: any(named: 'status'),
              orden: any(named: 'orden'),
              page: any(named: 'page'),
              size: any(named: 'size'),
            ),
          ).thenThrow(
            ApiException(
              status: 403,
              message: 'Acceso denegado',
              code: 'ACCESO_DENEGADO',
            ),
          ),
      build: cubit,
      act: (c) => c.cargar(),
      expect: () => [
        const UsuariosAdminCargando(),
        isA<UsuariosAdminError>().having(
          (s) => s.codigo,
          'codigo',
          'ACCESO_DENEGADO',
        ),
      ],
    );
  });

  group('filtros (HU 7.2 / 7.4)', () {
    test('filtrar(suspendido) asks only for suspended accounts', () async {
      final c = await cargado(_pagina([1]));

      await c.filtrar(EstadoCuenta.suspendido);

      verify(
        () => repo.usuarios(
          q: null,
          status: EstadoCuenta.suspendido,
          orden: OrdenUsuarios.recientes,
          page: 1,
          size: UsuariosAdminCubit.tamanoPagina,
        ),
      ).called(1);
      expect((c.state as UsuariosAdminCargado).status, EstadoCuenta.suspendido);
      await c.close();
    });

    test('ordenar re-queries with the new orden', () async {
      final c = await cargado(_pagina([1]));

      await c.ordenar(OrdenUsuarios.karma);

      verify(
        () => repo.usuarios(
          q: null,
          status: null,
          orden: OrdenUsuarios.karma,
          page: 1,
          size: UsuariosAdminCubit.tamanoPagina,
        ),
      ).called(1);
      await c.close();
    });

    test(
      'the filters keep the previous list while the new one loads',
      () async {
        final c = await cargado(_pagina([1, 2]));
        final respuesta = Completer<Pagina<UsuarioAdmin>>();
        when(
          () => repo.usuarios(
            q: any(named: 'q'),
            status: any(named: 'status'),
            orden: any(named: 'orden'),
            page: any(named: 'page'),
            size: any(named: 'size'),
          ),
        ).thenAnswer((_) => respuesta.future);

        final futuro = c.filtrar(EstadoCuenta.activo);
        final durante = c.state as UsuariosAdminCargado;

        expect(durante.actualizando, isTrue);
        expect(durante.usuarios, hasLength(2));
        respuesta.complete(_pagina([2]));
        await futuro;
        expect((c.state as UsuariosAdminCargado).actualizando, isFalse);
        await c.close();
      },
    );

    test('a slow older answer never overwrites the newest filter', () async {
      final lenta = Completer<Pagina<UsuarioAdmin>>();
      final c = cubit();
      when(
        () => repo.usuarios(
          q: any(named: 'q'),
          status: null,
          orden: any(named: 'orden'),
          page: any(named: 'page'),
          size: any(named: 'size'),
        ),
      ).thenAnswer((_) => lenta.future);
      when(
        () => repo.usuarios(
          q: any(named: 'q'),
          status: EstadoCuenta.suspendido,
          orden: any(named: 'orden'),
          page: any(named: 'page'),
          size: any(named: 'size'),
        ),
      ).thenAnswer((_) async => _pagina([9]));

      final primera = c.cargar();
      await c.filtrar(EstadoCuenta.suspendido);
      lenta.complete(_pagina([1, 2, 3]));
      await primera;

      expect((c.state as UsuariosAdminCargado).usuarios.map((u) => u.id), [9]);
      await c.close();
    });
  });

  group('buscar (debounce)', () {
    test('typing fast sends one request with the last text', () {
      fakeAsync((async) {
        stub(_pagina([1]));
        final c = cubit(espera: const Duration(milliseconds: 400));
        c.cargar();
        async.flushMicrotasks();
        clearInteractions(repo);

        c.buscar('lu');
        async.elapse(const Duration(milliseconds: 200));
        c.buscar('luc');
        async.elapse(const Duration(milliseconds: 200));
        verifyNever(
          () => repo.usuarios(
            q: any(named: 'q'),
            status: any(named: 'status'),
            orden: any(named: 'orden'),
            page: any(named: 'page'),
            size: any(named: 'size'),
          ),
        );
        async.elapse(const Duration(milliseconds: 250));
        async.flushMicrotasks();

        verify(
          () => repo.usuarios(
            q: 'luc',
            status: null,
            orden: OrdenUsuarios.recientes,
            page: 1,
            size: UsuariosAdminCubit.tamanoPagina,
          ),
        ).called(1);
        expect((c.state as UsuariosAdminCargado).q, 'luc');
        c.close();
      });
    });

    test('a single character never reaches the API as q', () {
      fakeAsync((async) {
        stub(_pagina([1]));
        final c = cubit(espera: const Duration(milliseconds: 100));
        c.cargar();
        async.flushMicrotasks();
        clearInteractions(repo);

        c.buscar('l');
        async.elapse(const Duration(milliseconds: 150));
        async.flushMicrotasks();

        verifyNever(
          () => repo.usuarios(
            q: any(named: 'q', that: isNotNull),
            status: any(named: 'status'),
            orden: any(named: 'orden'),
            page: any(named: 'page'),
            size: any(named: 'size'),
          ),
        );
        c.close();
      });
    });

    test('clearing a search reloads without q', () {
      fakeAsync((async) {
        stub(_pagina([1]));
        final c = cubit(espera: const Duration(milliseconds: 100));
        c.cargar();
        c.buscar('lucia');
        async.elapse(const Duration(milliseconds: 150));
        async.flushMicrotasks();
        clearInteractions(repo);

        c.buscar('   ');
        async.elapse(const Duration(milliseconds: 150));
        async.flushMicrotasks();

        verify(
          () => repo.usuarios(
            q: null,
            status: null,
            orden: OrdenUsuarios.recientes,
            page: 1,
            size: UsuariosAdminCubit.tamanoPagina,
          ),
        ).called(1);
        c.close();
      });
    });

    test('closing the cubit cancels a pending search', () {
      fakeAsync((async) {
        stub(_pagina([1]));
        final c = cubit(espera: const Duration(milliseconds: 100));
        c.cargar();
        async.flushMicrotasks();
        clearInteractions(repo);

        c.buscar('lucia');
        c.close();
        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();

        verifyNever(
          () => repo.usuarios(
            q: any(named: 'q'),
            status: any(named: 'status'),
            orden: any(named: 'orden'),
            page: any(named: 'page'),
            size: any(named: 'size'),
          ),
        );
      });
    });
  });

  group('cargarMas', () {
    test('appends the next page', () async {
      final c = await cargado(_pagina([1, 2], total: 3, totalPaginas: 2));
      when(
        () => repo.usuarios(
          q: any(named: 'q'),
          status: any(named: 'status'),
          orden: any(named: 'orden'),
          page: 2,
          size: any(named: 'size'),
        ),
      ).thenAnswer(
        (_) async => _pagina([3], page: 2, total: 3, totalPaginas: 2),
      );

      await c.cargarMas();

      final s = c.state as UsuariosAdminCargado;
      expect(s.usuarios.map((u) => u.id), [1, 2, 3]);
      expect(s.hayMas, isFalse);
      await c.close();
    });

    test('does nothing on the last page', () async {
      final c = await cargado(_pagina([1]));
      clearInteractions(repo);

      await c.cargarMas();

      verifyNever(
        () => repo.usuarios(
          q: any(named: 'q'),
          status: any(named: 'status'),
          orden: any(named: 'orden'),
          page: any(named: 'page'),
          size: any(named: 'size'),
        ),
      );
      await c.close();
    });

    test('a second call while one is in flight is ignored', () async {
      final c = await cargado(_pagina([1], total: 2, totalPaginas: 2));
      final respuesta = Completer<Pagina<UsuarioAdmin>>();
      when(
        () => repo.usuarios(
          q: any(named: 'q'),
          status: any(named: 'status'),
          orden: any(named: 'orden'),
          page: 2,
          size: any(named: 'size'),
        ),
      ).thenAnswer((_) => respuesta.future);

      final a = c.cargarMas();
      final b = c.cargarMas();
      respuesta.complete(_pagina([2], page: 2, total: 2, totalPaginas: 2));
      await Future.wait([a, b]);

      verify(
        () => repo.usuarios(
          q: any(named: 'q'),
          status: any(named: 'status'),
          orden: any(named: 'orden'),
          page: 2,
          size: any(named: 'size'),
        ),
      ).called(1);
      expect((c.state as UsuariosAdminCargado).usuarios, hasLength(2));
      await c.close();
    });

    test('a failure keeps the list and reports an aviso', () async {
      final c = await cargado(_pagina([1], total: 2, totalPaginas: 2));
      when(
        () => repo.usuarios(
          q: any(named: 'q'),
          status: any(named: 'status'),
          orden: any(named: 'orden'),
          page: 2,
          size: any(named: 'size'),
        ),
      ).thenThrow(ApiException(status: 500, message: 'Falló', code: 'X'));

      await c.cargarMas();

      final s = c.state as UsuariosAdminCargado;
      expect(s.usuarios, hasLength(1));
      expect(s.aviso, 'Falló');
      expect(s.cargandoMas, isFalse);
      c.descartarAviso();
      expect((c.state as UsuariosAdminCargado).aviso, isNull);
      await c.close();
    });
  });

  test('closing while a request is in flight never emits afterwards', () async {
    final respuesta = Completer<Pagina<UsuarioAdmin>>();
    when(
      () => repo.usuarios(
        q: any(named: 'q'),
        status: any(named: 'status'),
        orden: any(named: 'orden'),
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).thenAnswer((_) => respuesta.future);
    final c = cubit();

    final futuro = c.cargar();
    await c.close();
    respuesta.complete(_pagina([1]));

    await expectLater(futuro, completes);
    expect(c.state, const UsuariosAdminCargando());
  });

  group('common errors', () {
    When<Future<Pagina<UsuarioAdmin>>> cuandoPide() => when(
      () => repo.usuarios(
        q: any(named: 'q'),
        status: any(named: 'status'),
        orden: any(named: 'orden'),
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    );

    testErroresComunes('a failed first load ends as UsuariosAdminError', (
      caso,
    ) async {
      cuandoPide().thenThrow(caso.error);
      final c = cubit();

      await c.cargar();

      expect(
        c.state,
        UsuariosAdminError(
          caso.mensaje,
          codigo: caso.error.code,
          esSinConexion: caso.esSinConexion,
        ),
      );
      await c.close();
    });

    testErroresComunes('a failed filter change keeps the list with an aviso', (
      caso,
    ) async {
      final c = await cargado(_pagina([1, 2]));
      cuandoPide().thenThrow(caso.error);

      await c.filtrar(EstadoCuenta.suspendido);

      final estado = c.state as UsuariosAdminCargado;
      expect(estado.usuarios.map((u) => u.id), [1, 2]);
      expect(estado.actualizando, isFalse);
      expect(estado.aviso, caso.mensaje);
      await c.close();
    });
  });
}
