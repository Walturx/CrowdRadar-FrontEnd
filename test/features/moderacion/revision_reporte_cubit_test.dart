import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:crowdradar/core/models/moderacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/features/moderacion/data/moderacion_repository.dart';
import 'package:crowdradar/features/moderacion/revision_reporte/revision_reporte_cubit.dart';
import 'package:crowdradar/features/moderacion/revision_reporte/revision_reporte_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'json_moderacion.dart';
import '../../helpers/errores_comunes.dart';

class _MockRepo extends Mock implements ModeracionRepository {}

final _detalle = DetalleReporteDenunciado.fromJson(detalleReporteJson());
final _eliminado = ResolucionReporte.fromJson(resolucionJson());
final _mantenido = ResolucionReporte.fromJson(resolucionJson(estado: 'ACTIVO'));

ApiException _api(int status, String code, [String msg = 'mensaje del API']) =>
    ApiException(status: status, message: msg, code: code);

void main() {
  late _MockRepo repo;

  setUpAll(() => registerFallbackValue(DecisionModeracion.mantener));
  setUp(() => repo = _MockRepo());

  RevisionReporteCubit cubit() => RevisionReporteCubit(repo, 201);

  Future<RevisionReporteCubit> cargado() async {
    when(() => repo.reporteDenunciado(201)).thenAnswer((_) async => _detalle);
    final c = cubit();
    await c.cargar();
    return c;
  }

  group('cargar (HU 7.1 c2)', () {
    blocTest<RevisionReporteCubit, RevisionReporteState>(
      'loads the detail with motivos and author',
      setUp: () => when(
        () => repo.reporteDenunciado(201),
      ).thenAnswer((_) async => _detalle),
      build: cubit,
      act: (c) => c.cargar(),
      expect: () => [
        const RevisionReporteCargando(),
        RevisionReporteCargado(detalle: _detalle),
      ],
    );

    blocTest<RevisionReporteCubit, RevisionReporteState>(
      '404 REPORTE_NO_ENCONTRADO is a stale report, not a retryable error',
      setUp: () => when(
        () => repo.reporteDenunciado(201),
      ).thenThrow(_api(404, 'REPORTE_NO_ENCONTRADO', 'Reporte no encontrado')),
      build: cubit,
      act: (c) => c.cargar(),
      expect: () => [
        const RevisionReporteCargando(),
        const RevisionReporteObsoleta('Reporte no encontrado'),
      ],
    );

    blocTest<RevisionReporteCubit, RevisionReporteState>(
      'offline is an error with retry information',
      setUp: () => when(
        () => repo.reporteDenunciado(201),
      ).thenThrow(const ApiException.sinConexion()),
      build: cubit,
      act: (c) => c.cargar(),
      expect: () => [
        const RevisionReporteCargando(),
        isA<RevisionReporteError>().having(
          (s) => s.esSinConexion,
          'offline',
          true,
        ),
      ],
    );
  });

  group('resolver (HU 7.1 c3)', () {
    test('ELIMINAR sends the decision and ends with the new estado', () async {
      final c = await cargado();
      when(
        () => repo.resolver(201, DecisionModeracion.eliminar, comentario: null),
      ).thenAnswer((_) async => _eliminado);

      await c.resolver(DecisionModeracion.eliminar);

      verify(
        () => repo.resolver(201, DecisionModeracion.eliminar, comentario: null),
      ).called(1);
      expect(
        c.state,
        RevisionReporteResuelta(detalle: _detalle, resolucion: _eliminado),
      );
      await c.close();
    });

    test('MANTENER passes the trimmed comentario', () async {
      final c = await cargado();
      when(
        () => repo.resolver(
          201,
          DecisionModeracion.mantener,
          comentario: 'Sin infracción',
        ),
      ).thenAnswer((_) async => _mantenido);

      await c.resolver(
        DecisionModeracion.mantener,
        comentario: '  Sin infracción ',
      );

      expect(
        (c.state as RevisionReporteResuelta).resolucion.estado,
        EstadoReporteModerado.activo,
      );
      await c.close();
    });

    test('marks the decision in flight and ignores a second tap', () async {
      final c = await cargado();
      final respuesta = Completer<ResolucionReporte>();
      when(
        () => repo.resolver(any(), any(), comentario: any(named: 'comentario')),
      ).thenAnswer((_) => respuesta.future);

      final a = c.resolver(DecisionModeracion.eliminar);
      final b = c.resolver(DecisionModeracion.mantener);
      expect((c.state as RevisionReporteCargado).resolviendo, isTrue);
      respuesta.complete(_eliminado);
      await Future.wait([a, b]);

      verify(
        () => repo.resolver(any(), any(), comentario: any(named: 'comentario')),
      ).called(1);
      await c.close();
    });

    test('a failure rolls back to the buttons with the notice', () async {
      final c = await cargado();
      when(
        () => repo.resolver(any(), any(), comentario: any(named: 'comentario')),
      ).thenThrow(const ApiException.sinConexion());

      await c.resolver(DecisionModeracion.eliminar);

      final s = c.state as RevisionReporteCargado;
      expect(s.resolviendo, isFalse);
      expect(s.aviso, ApiException.mensajeSinConexion);
      expect(s.detalle, _detalle);
      c.descartarAviso();
      expect((c.state as RevisionReporteCargado).aviso, isNull);
      await c.close();
    });

    test(
      '409 SIN_DENUNCIAS_PENDIENTES means someone else already resolved it',
      () async {
        final c = await cargado();
        when(
          () =>
              repo.resolver(any(), any(), comentario: any(named: 'comentario')),
        ).thenThrow(
          _api(409, 'SIN_DENUNCIAS_PENDIENTES', 'Sin denuncias pendientes'),
        );

        await c.resolver(DecisionModeracion.eliminar);

        expect(
          c.state,
          const RevisionReporteObsoleta('Sin denuncias pendientes'),
        );
        await c.close();
      },
    );

    test('a comentario over 280 characters never reaches the API', () async {
      final c = await cargado();

      await c.resolver(DecisionModeracion.mantener, comentario: 'x' * 281);

      verifyNever(
        () => repo.resolver(any(), any(), comentario: any(named: 'comentario')),
      );
      expect(
        (c.state as RevisionReporteCargado).aviso,
        RevisionReporteCubit.mensajeComentarioLargo,
      );
      await c.close();
    });

    test('closing while the request is in flight never emits', () async {
      final c = await cargado();
      final respuesta = Completer<ResolucionReporte>();
      when(
        () => repo.resolver(any(), any(), comentario: any(named: 'comentario')),
      ).thenAnswer((_) => respuesta.future);

      final futuro = c.resolver(DecisionModeracion.eliminar);
      await c.close();
      respuesta.complete(_eliminado);

      await expectLater(futuro, completes);
    });
  });

  group('common errors', () {
    testErroresComunes('a failed load ends as a retryable Error', (caso) async {
      when(() => repo.reporteDenunciado(201)).thenThrow(caso.error);
      final c = cubit();

      await c.cargar();

      expect(
        c.state,
        RevisionReporteError(
          caso.mensaje,
          codigo: caso.error.code,
          esSinConexion: caso.esSinConexion,
        ),
      );
      await c.close();
    });

    testErroresComunes('a failed decision rolls back to the buttons', (
      caso,
    ) async {
      final c = await cargado();
      when(
        () => repo.resolver(201, any(), comentario: any(named: 'comentario')),
      ).thenThrow(caso.error);

      await c.resolver(DecisionModeracion.eliminar);

      expect(
        c.state,
        RevisionReporteCargado(detalle: _detalle, aviso: caso.mensaje),
      );
      await c.close();
    });
  });
}
