import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:crowdradar/core/map/centro_compartido.dart';
import 'package:crowdradar/core/map/tipos_mapa.dart';
import 'package:crowdradar/core/models/validacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/network/respuesta_api.dart';
import 'package:crowdradar/features/validacion/data/validacion_repository.dart';
import 'package:crowdradar/features/validacion/pendientes/pendientes_cubit.dart';
import 'package:crowdradar/features/validacion/pendientes/pendientes_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'json_validacion.dart';
import '../../helpers/errores_comunes.dart';

class _MockRepo extends Mock implements ValidacionRepository {}

ReportePendiente _r(int id) => ReportePendiente.fromJson(pendienteJson(id: id));

Pagina<ReportePendiente> _pagina(List<int> ids) => Pagina(
  items: [for (final i in ids) _r(i)],
  page: 1,
  size: 20,
  total: ids.length,
  totalPaginas: 1,
);

const _voto = ResultadoVoto(
  accion: TipoAccionValidacion.confirmar,
  puntosGanados: 2,
  totalKarma: 112,
  confiabilidad: Confiabilidad(porcentaje: 80, nivel: NivelConfiabilidad.alta),
  estadoValidacion: EstadoValidacion.enValidacion,
);

ApiException _api(int status, String code, [String msg = 'mensaje del API']) =>
    ApiException(status: status, message: msg, code: code);

void main() {
  late _MockRepo repo;
  late CentroMapaCompartido centro;

  setUpAll(() => registerFallbackValue(TipoAccionValidacion.confirmar));

  setUp(() {
    repo = _MockRepo();
    centro = CentroMapaCompartido();
  });

  PendientesCubit cubit() => PendientesCubit(repo, centro);

  void stubPendientes(List<int> ids) => when(
    () => repo.pendientes(
      lat: any(named: 'lat'),
      lng: any(named: 'lng'),
    ),
  ).thenAnswer((_) async => _pagina(ids));

  Future<PendientesCubit> cargado(List<int> ids) async {
    stubPendientes(ids);
    final c = cubit();
    await c.cargar();
    return c;
  }

  group('cargar', () {
    blocTest<PendientesCubit, PendientesState>(
      'uses the last map centre',
      setUp: () {
        centro.actualizar(
          const LimitesMapa(norte: -12, sur: -13, este: -76, oeste: -77),
        );
        stubPendientes([1, 2]);
      },
      build: cubit,
      act: (c) => c.cargar(),
      expect: () => [
        const PendientesCargando(),
        PendientesCargado(reportes: [_r(1), _r(2)]),
      ],
      verify: (_) =>
          verify(() => repo.pendientes(lat: -12.5, lng: -76.5)).called(1),
    );

    blocTest<PendientesCubit, PendientesState>(
      'falls back to the centre of Lima without a map centre',
      setUp: () => stubPendientes([]),
      build: cubit,
      act: (c) => c.cargar(),
      expect: () => [
        const PendientesCargando(),
        const PendientesCargado(reportes: []),
      ],
      verify: (_) => verify(
        () => repo.pendientes(
          lat: CentroMapaCompartido.lima.latitud,
          lng: CentroMapaCompartido.lima.longitud,
        ),
      ).called(1),
    );

    blocTest<PendientesCubit, PendientesState>(
      'a failure is an Error with its code and offline flag',
      setUp: () => when(
        () => repo.pendientes(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
        ),
      ).thenThrow(const ApiException.sinConexion()),
      build: cubit,
      act: (c) => c.cargar(),
      expect: () => [
        const PendientesCargando(),
        isA<PendientesError>().having(
          (e) => e.esSinConexion,
          'esSinConexion',
          true,
        ),
      ],
    );

    test(
      'a refresh over a loaded list keeps it and adds a soft error',
      () async {
        final c = await cargado([1]);
        when(
          () => repo.pendientes(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenThrow(_api(500, 'ERROR', 'caído'));

        await c.cargar();

        expect(c.state, PendientesCargado(reportes: [_r(1)], aviso: 'caído'));
      },
    );

    test('a load while another is in flight is ignored', () async {
      final espera = Completer<Pagina<ReportePendiente>>();
      when(
        () => repo.pendientes(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
        ),
      ).thenAnswer((_) => espera.future);
      final c = cubit();

      final a = c.cargar();
      final b = c.cargar();
      espera.complete(_pagina([1]));
      await Future.wait([a, b]);

      verify(
        () => repo.pendientes(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
        ),
      ).called(1);
    });
  });

  group('votar', () {
    test('cargar during a vote keeps votando and ultimoVoto and does not '
        'resurrect the report', () async {
      final c = await cargado([1, 2]);
      final espera = Completer<ResultadoVoto>();
      when(
        () => repo.validar(1, TipoAccionValidacion.confirmar),
      ).thenAnswer((_) => espera.future);
      final f = c.votar(_r(1), TipoAccionValidacion.confirmar);

      stubPendientes([1, 2, 3]);
      await c.cargar();

      final s = c.state as PendientesCargado;
      expect([for (final r in s.reportes) r.id], [2, 3]);
      expect(s.votando, {1});
      espera.complete(_voto);
      await f;
      await c.cargar();
      expect((c.state as PendientesCargado).ultimoVoto, isNotNull);
    });

    test('429 on a vote says to wait and keeps the report restored', () async {
      final c = await cargado([1, 2]);
      when(() => repo.validar(1, TipoAccionValidacion.confirmar)).thenThrow(
        const ApiException(
          status: 429,
          message: 'x',
          code: 'DEMASIADAS_SOLICITUDES',
          reintentarEnSegundos: 120,
        ),
      );

      await c.votar(_r(1), TipoAccionValidacion.confirmar);

      final s = c.state as PendientesCargado;
      expect([for (final r in s.reportes) r.id], [1, 2]);
      expect(s.aviso, 'Demasiadas acciones seguidas, probá en 2 minutos');
    });
    test(
      'removes the report at once, then records the vote and karma',
      () async {
        final c = await cargado([1, 2]);
        final espera = Completer<ResultadoVoto>();
        when(
          () => repo.validar(1, TipoAccionValidacion.confirmar),
        ).thenAnswer((_) => espera.future);

        final f = c.votar(_r(1), TipoAccionValidacion.confirmar);

        expect(
          c.state,
          PendientesCargado(reportes: [_r(2)], votando: const {1}),
        );
        espera.complete(_voto);
        await f;
        expect(
          c.state,
          PendientesCargado(
            reportes: [_r(2)],
            ultimoVoto: VotoRegistrado(
              reporte: _r(1),
              accion: TipoAccionValidacion.confirmar,
              puntosGanados: 2,
            ),
          ),
        );
      },
    );

    test(
      'a failure puts the report back where it was, with the message',
      () async {
        final c = await cargado([1, 2, 3]);
        when(
          () => repo.validar(2, TipoAccionValidacion.rechazar),
        ).thenThrow(const ApiException.sinConexion());

        await c.votar(_r(2), TipoAccionValidacion.rechazar);

        final s = c.state as PendientesCargado;
        expect([for (final r in s.reportes) r.id], [1, 2, 3]);
        expect(s.aviso, isNotNull);
        expect(s.votando, isEmpty);
        expect(s.ultimoVoto, isNull);
      },
    );

    test('409 keeps it removed and says the user already took part', () async {
      final c = await cargado([1, 2]);
      when(
        () => repo.validar(1, TipoAccionValidacion.confirmar),
      ).thenThrow(_api(409, 'VALIDACION_DUPLICADA'));

      await c.votar(_r(1), TipoAccionValidacion.confirmar);

      final s = c.state as PendientesCargado;
      expect([for (final r in s.reportes) r.id], [2]);
      expect(s.aviso, PendientesCubit.mensajeYaParticipo);
    });

    test('404 and 422 keep it removed and show the server message', () async {
      final c = await cargado([1, 2, 3]);
      when(
        () => repo.validar(1, TipoAccionValidacion.confirmar),
      ).thenThrow(_api(404, 'REPORTE_NO_ENCONTRADO', 'Ya no existe'));
      when(
        () => repo.validar(2, TipoAccionValidacion.confirmar),
      ).thenThrow(_api(422, 'AUTOVALIDACION_NO_PERMITIDA', 'Es tuyo'));

      await c.votar(_r(1), TipoAccionValidacion.confirmar);
      expect((c.state as PendientesCargado).aviso, 'Ya no existe');
      await c.votar(_r(2), TipoAccionValidacion.confirmar);

      final s = c.state as PendientesCargado;
      expect([for (final r in s.reportes) r.id], [3]);
      expect(s.aviso, 'Es tuyo');
    });

    test('a second vote on a report already in flight is ignored', () async {
      final c = await cargado([1]);
      final espera = Completer<ResultadoVoto>();
      when(() => repo.validar(1, any())).thenAnswer((_) => espera.future);

      final a = c.votar(_r(1), TipoAccionValidacion.confirmar);
      final b = c.votar(_r(1), TipoAccionValidacion.rechazar);
      espera.complete(_voto);
      await Future.wait([a, b]);

      verify(() => repo.validar(1, any())).called(1);
    });

    test('a report that is not in the list is ignored', () async {
      final c = await cargado([1]);

      await c.votar(_r(9), TipoAccionValidacion.confirmar);

      verifyNever(() => repo.validar(any(), any()));
    });

    test(
      'closing the cubit while the vote is in flight does not emit',
      () async {
        final c = await cargado([1]);
        final espera = Completer<ResultadoVoto>();
        when(() => repo.validar(1, any())).thenAnswer((_) => espera.future);

        final f = c.votar(_r(1), TipoAccionValidacion.confirmar);
        await c.close();
        espera.complete(_voto);

        await expectLater(f, completes);
      },
    );

    test('descartarAviso clears the message', () async {
      final c = await cargado([1]);
      when(
        () => repo.validar(1, any()),
      ).thenThrow(_api(409, 'VALIDACION_DUPLICADA'));
      await c.votar(_r(1), TipoAccionValidacion.confirmar);

      c.descartarAviso();

      expect((c.state as PendientesCargado).aviso, isNull);
    });
  });

  group('common errors', () {
    testErroresComunes('a failed first load ends as PendientesError', (
      caso,
    ) async {
      when(
        () => repo.pendientes(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
        ),
      ).thenThrow(caso.error);
      final c = cubit();

      await c.cargar();

      expect(
        c.state,
        PendientesError(
          caso.mensaje,
          codigo: caso.error.code,
          esSinConexion: caso.esSinConexion,
        ),
      );
      await c.close();
    });

    testErroresComunes('a failed vote puts the report back with a notice', (
      caso,
    ) async {
      final c = await cargado([1, 2]);
      when(() => repo.validar(1, any())).thenThrow(caso.error);

      await c.votar(_r(1), TipoAccionValidacion.confirmar);

      expect(
        c.state,
        PendientesCargado(reportes: [_r(1), _r(2)], aviso: caso.mensaje),
      );
      await c.close();
    });
  });
}
