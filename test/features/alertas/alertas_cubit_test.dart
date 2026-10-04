import 'dart:async';

import 'package:crowdradar/app/fakes/alerta_repository_fake.dart';
import 'package:crowdradar/app/fakes/comportamiento_fake.dart';
import 'package:crowdradar/core/models/alerta.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/network/respuesta_api.dart';
import 'package:crowdradar/features/alertas/data/alerta_repository.dart';
import 'package:crowdradar/features/alertas/lista/alertas_cubit.dart';
import 'package:crowdradar/features/alertas/lista/alertas_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements AlertaRepository {}

Alerta _alerta(int id, {bool leida = false}) => Alerta(
  id: id,
  lugarId: id,
  lugarNombre: 'Lugar $id',
  nivelAnterior: NivelSaturacion.moderado,
  nivelNuevo: NivelSaturacion.saturado,
  mensaje: 'm',
  leida: leida,
);

PaginaAlertas _pagina(List<Alerta> items, int noLeidas, {String mensaje = ''}) =>
    PaginaAlertas(
      pagina: Pagina(
        items: items,
        page: 1,
        size: 20,
        total: items.length,
        totalPaginas: 1,
      ),
      noLeidas: noLeidas,
      mensaje: mensaje,
    );

AlertasCargado _cargado(AlertasCubit c) => c.state as AlertasCargado;

void main() {
  group('cargar', () {
    test('emits Cargando then Cargado with the alerts and unread count', () async {
      final cubit = AlertasCubit(AlertaRepositoryFake());
      final estados = <AlertasState>[];
      cubit.stream.listen(estados.add);

      await cubit.cargar();
      await pumpEventQueue();

      expect(estados.first, const AlertasCargando());
      expect(_cargado(cubit).alertas, hasLength(2));
      expect(_cargado(cubit).noLeidas, 1);
      expect(cubit.noLeidas, 1);
      await cubit.close();
    });

    test('no alerts carries the server message and zero unread', () async {
      final cubit = AlertasCubit(AlertaRepositoryFake(sembrar: false));

      await cubit.cargar();

      expect(_cargado(cubit).alertas, isEmpty);
      expect(_cargado(cubit).mensajeVacio, 'No tienes alertas.');
      expect(cubit.noLeidas, 0);
      await cubit.close();
    });

    test('unread alerts come first', () async {
      final repo = _MockRepo();
      when(() => repo.listar()).thenAnswer(
        (_) async => _pagina([_alerta(3, leida: true), _alerta(2), _alerta(1)], 2),
      );
      final cubit = AlertasCubit(repo);

      await cubit.cargar();

      expect(_cargado(cubit).alertas.map((a) => a.id), [2, 1, 3]);
      await cubit.close();
    });

    test('failure emits Error with code and offline flag; retry loads', () async {
      final repo = _MockRepo();
      var n = 0;
      when(() => repo.listar()).thenAnswer((_) async {
        if (n++ == 0) throw const ApiException.sinConexion();
        return _pagina([_alerta(1)], 1);
      });
      final cubit = AlertasCubit(repo);

      await cubit.cargar();
      expect((cubit.state as AlertasError).esSinConexion, isTrue);
      expect(cubit.noLeidas, 0);

      await cubit.cargar();
      expect(_cargado(cubit).alertas, hasLength(1));
      await cubit.close();
    });

    test('a second load while one is in flight is ignored', () async {
      final repo = _MockRepo();
      final completer = Completer<PaginaAlertas>();
      when(() => repo.listar()).thenAnswer((_) => completer.future);
      final cubit = AlertasCubit(repo);

      final a = cubit.cargar();
      final b = cubit.cargar();
      completer.complete(_pagina([], 0));
      await Future.wait([a, b]);

      verify(() => repo.listar()).called(1);
      await cubit.close();
    });

    test('closing while loading does not emit afterwards', () async {
      final repo = _MockRepo();
      final completer = Completer<PaginaAlertas>();
      when(() => repo.listar()).thenAnswer((_) => completer.future);
      final cubit = AlertasCubit(repo);

      final carga = cubit.cargar();
      await cubit.close();
      completer.complete(_pagina([], 0));

      await expectLater(carga, completes);
    });
  });

  group('marcarLeida', () {
    test('lowers the unread count at once and calls the repository', () async {
      final repo = AlertaRepositoryFake();
      final cubit = AlertasCubit(repo);
      await cubit.cargar();
      final id = _cargado(cubit).alertas.first.id;
      final estados = <AlertasState>[];
      cubit.stream.listen(estados.add);

      final futuro = cubit.marcarLeida(id);
      await pumpEventQueue();
      expect((estados.first as AlertasCargado).noLeidas, 0);
      await futuro;

      expect(cubit.noLeidas, 0);
      expect(_cargado(cubit).alertas.every((a) => a.leida), isTrue);
      expect((await repo.listar()).noLeidas, 0);
      await cubit.close();
    });

    test('an already read alert does not change the count', () async {
      final cubit = AlertasCubit(AlertaRepositoryFake());
      await cubit.cargar();
      final leida = _cargado(cubit).alertas.firstWhere((a) => a.leida);

      await cubit.marcarLeida(leida.id);

      expect(cubit.noLeidas, 1);
      await cubit.close();
    });

    test('a failure restores the alert as unread and reports it', () async {
      final repo = _MockRepo();
      when(() => repo.listar()).thenAnswer((_) async => _pagina([_alerta(1)], 1));
      when(
        () => repo.marcarLeida(1),
      ).thenThrow(const ApiException(status: 500, message: 'Servidor caído'));
      final cubit = AlertasCubit(repo);
      await cubit.cargar();

      await cubit.marcarLeida(1);

      expect(cubit.noLeidas, 1);
      expect(_cargado(cubit).alertas.single.leida, isFalse);
      expect(_cargado(cubit).error, 'Servidor caído');
      await cubit.close();
    });

    test('a 404 keeps it as read without an error', () async {
      final repo = _MockRepo();
      when(() => repo.listar()).thenAnswer((_) async => _pagina([_alerta(1)], 1));
      when(() => repo.marcarLeida(1)).thenThrow(
        const ApiException(
          status: 404,
          message: 'x',
          code: 'ALERTA_NO_ENCONTRADA',
        ),
      );
      final cubit = AlertasCubit(repo);
      await cubit.cargar();

      await cubit.marcarLeida(1);

      expect(cubit.noLeidas, 0);
      expect(_cargado(cubit).error, isNull);
      await cubit.close();
    });

    test('is ignored while there are no loaded alerts', () async {
      final repo = _MockRepo();
      final cubit = AlertasCubit(repo);

      await cubit.marcarLeida(1);

      verifyNever(() => repo.marcarLeida(any()));
      await cubit.close();
    });
  });

  group('refrescar', () {
    test('refreshes in the background and picks up new alerts', () async {
      final repo = AlertaRepositoryFake(sembrar: false);
      final cubit = AlertasCubit(repo);
      await cubit.cargar();
      expect(cubit.noLeidas, 0);
      final estados = <AlertasState>[];
      cubit.stream.listen(estados.add);

      repo.emitir(3, NivelSaturacion.tranquilo, NivelSaturacion.saturado);
      await cubit.refrescar();
      await pumpEventQueue();

      expect(estados.any((e) => e is AlertasCargando), isFalse);
      expect(cubit.noLeidas, 1);
      expect(_cargado(cubit).alertas.single.lugarId, 3);
      await cubit.close();
    });

    test('a failed refresh keeps the alerts and adds a soft error', () async {
      final repo = _MockRepo();
      var n = 0;
      when(() => repo.listar()).thenAnswer((_) async {
        if (n++ == 0) return _pagina([_alerta(1)], 1);
        throw const ApiException(status: 500, message: 'Servidor caído');
      });
      final cubit = AlertasCubit(repo);
      await cubit.cargar();

      await cubit.refrescar();

      expect(_cargado(cubit).alertas, hasLength(1));
      expect(cubit.noLeidas, 1);
      expect(_cargado(cubit).error, 'Servidor caído');
      await cubit.close();
    });

    test('a mark made during the reload stays read (R3-804)', () async {
      final repo = _MockRepo();
      final lenta = Completer<PaginaAlertas>();
      var n = 0;
      when(() => repo.listar()).thenAnswer((_) {
        if (n++ == 0) return Future.value(_pagina([_alerta(1), _alerta(2)], 2));
        return lenta.future;
      });
      when(() => repo.marcarLeida(1)).thenAnswer((_) async {});
      final cubit = AlertasCubit(repo);
      await cubit.cargar();

      final refresco = cubit.refrescar();
      await pumpEventQueue();
      await cubit.marcarLeida(1);
      lenta.complete(_pagina([_alerta(1), _alerta(2)], 2)); // server was stale
      await refresco;

      expect(_cargado(cubit).alertas.firstWhere((a) => a.id == 1).leida, isTrue);
      expect(cubit.noLeidas, 1);
      await cubit.close();
    });

    test('a failed mark after the refresh leaves the count at the list', () async {
      final repo = _MockRepo();
      final marca = Completer<void>();
      when(() => repo.listar()).thenAnswer(
        (_) async => _pagina([_alerta(1), _alerta(2)], 2),
      );
      when(() => repo.marcarLeida(1)).thenAnswer((_) => marca.future);
      final cubit = AlertasCubit(repo);
      await cubit.cargar();

      final marcando = cubit.marcarLeida(1);
      await cubit.refrescar();
      marca.completeError(const ApiException.sinConexion());
      await marcando;

      final estado = _cargado(cubit);
      expect(estado.noLeidas, estado.alertas.where((a) => !a.leida).length);
      await cubit.close();
    });

    test('a failed refresh keeps a mark made while it ran', () async {
      final repo = _MockRepo();
      final lenta = Completer<PaginaAlertas>();
      var n = 0;
      when(() => repo.listar()).thenAnswer((_) {
        if (n++ == 0) return Future.value(_pagina([_alerta(1), _alerta(2)], 2));
        return lenta.future;
      });
      when(() => repo.marcarLeida(1)).thenAnswer((_) async {});
      final cubit = AlertasCubit(repo);
      await cubit.cargar();

      final refresco = cubit.refrescar();
      await pumpEventQueue();
      await cubit.marcarLeida(1);
      lenta.completeError(const ApiException.sinConexion());
      await refresco;

      expect(_cargado(cubit).alertas.firstWhere((a) => a.id == 1).leida, isTrue);
      expect(cubit.noLeidas, 1);
      await cubit.close();
    });

    test('marking the same alert twice at once sends one request', () async {
      final repo = _MockRepo();
      final marca = Completer<void>();
      when(() => repo.listar()).thenAnswer(
        (_) async => _pagina([_alerta(1), _alerta(2)], 2),
      );
      when(() => repo.marcarLeida(1)).thenAnswer((_) => marca.future);
      final cubit = AlertasCubit(repo);
      await cubit.cargar();

      final a = cubit.marcarLeida(1);
      final b = cubit.marcarLeida(1);
      marca.complete();
      await Future.wait([a, b]);

      verify(() => repo.marcarLeida(1)).called(1);
      expect(cubit.noLeidas, 1);
      await cubit.close();
    });

    test('without data it behaves like cargar', () async {
      final cubit = AlertasCubit(AlertaRepositoryFake());

      await cubit.refrescar();

      expect(_cargado(cubit).alertas, hasLength(2));
      await cubit.close();
    });
  });

  group('alVolverAPrimerPlano (R4-806 / R4-808)', () {
    late DateTime ahora;
    late _MockRepo repo;
    var falla = false;
    var llamadas = 0;

    AlertasCubit crear() => AlertasCubit(repo, reloj: () => ahora);

    setUp(() {
      ahora = DateTime(2026, 10, 5, 12);
      falla = false;
      llamadas = 0;
      repo = _MockRepo();
      when(() => repo.listar()).thenAnswer((_) async {
        llamadas++;
        if (falla) throw const ApiException.sinConexion();
        return _pagina([_alerta(1)], 1);
      });
    });

    test('a resume right after a load does not reload', () async {
      final cubit = crear();
      await cubit.cargar();

      ahora = ahora.add(const Duration(seconds: 29));
      await cubit.alVolverAPrimerPlano();

      expect(llamadas, 1);
      await cubit.close();
    });

    test('a resume after the interval refreshes', () async {
      final cubit = crear();
      await cubit.cargar();

      ahora = ahora.add(AlertasCubit.intervaloRefresco);
      await cubit.alVolverAPrimerPlano();

      expect(llamadas, 2);
      await cubit.close();
    });

    test('a failed first load is retried on the next resume and flagged', () async {
      falla = true;
      final cubit = crear();
      await cubit.cargar();
      expect(cubit.errorCarga, isTrue);
      expect(cubit.noLeidas, 0);

      falla = false;
      await cubit.alVolverAPrimerPlano();

      expect(llamadas, 2);
      expect(cubit.errorCarga, isFalse);
      expect(cubit.noLeidas, 1);
      await cubit.close();
    });
  });

  test('against a failing fake the state is Error', () async {
    final cubit = AlertasCubit(
      AlertaRepositoryFake(
        comportamiento: const ComportamientoFake(
          fallo: ApiException(status: 503, message: 'Caído', code: 'X'),
        ),
      ),
    );

    await cubit.cargar();

    expect(cubit.state, const AlertasError('Caído', codigo: 'X'));
    await cubit.close();
  });
}
