import 'dart:async';

import 'package:crowdradar/core/models/validacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/features/validacion/data/validacion_repository.dart';
import 'package:crowdradar/features/validacion/detalle_reporte/detalle_reporte_cubit.dart';
import 'package:crowdradar/features/validacion/detalle_reporte/detalle_reporte_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'json_validacion.dart';
import '../../helpers/errores_comunes.dart';

class _MockRepo extends Mock implements ValidacionRepository {}

DetalleReporte _detalle({
  String? miValidacion,
  bool esPropio = false,
  Map<String, dynamic>? conf,
}) => DetalleReporte.fromJson(
  detalleJson(miValidacion: miValidacion, esPropio: esPropio, conf: conf),
);

const _voto = ResultadoVoto(
  accion: TipoAccionValidacion.rechazar,
  puntosGanados: 2,
  totalKarma: 112,
  confiabilidad: Confiabilidad(
    porcentaje: 38.46,
    nivel: NivelConfiabilidad.baja,
    confirmaciones: 5,
    rechazos: 8,
    advertencia: advertenciaBaja,
  ),
  estadoValidacion: EstadoValidacion.rechazado,
);

ApiException _api(int status, String code, [String msg = 'mensaje del API']) =>
    ApiException(status: status, message: msg, code: code);

void main() {
  late _MockRepo repo;

  setUpAll(() => registerFallbackValue(TipoAccionValidacion.confirmar));
  setUp(() => repo = _MockRepo());

  Future<DetalleReporteCubit> cargado([DetalleReporte? d]) async {
    when(
      () => repo.obtenerReporte(31),
    ).thenAnswer((_) async => d ?? _detalle());
    final c = DetalleReporteCubit(repo, 31);
    await c.cargar();
    return c;
  }

  DetalleCargado estado(DetalleReporteCubit c) => c.state as DetalleCargado;

  group('cargar', () {
    test('Cargando then Cargado with the detail', () async {
      when(() => repo.obtenerReporte(31)).thenAnswer((_) async => _detalle());
      final c = DetalleReporteCubit(repo, 31);
      final estados = <DetalleState>[];
      c.stream.listen(estados.add);

      await c.cargar();
      await Future<void>.delayed(Duration.zero);

      expect(estados, [DetalleCargado(_detalle())]);
      expect(c.state, DetalleCargado(_detalle()));
    });

    test('a 404 is an Error carrying its code', () async {
      when(
        () => repo.obtenerReporte(31),
      ).thenThrow(_api(404, 'REPORTE_NO_ENCONTRADO'));
      final c = DetalleReporteCubit(repo, 31);

      await c.cargar();

      expect(
        c.state,
        isA<DetalleError>().having(
          (e) => e.codigo,
          'codigo',
          'REPORTE_NO_ENCONTRADO',
        ),
      );
    });

    test('a refresh failure keeps the detail and adds a notice', () async {
      final c = await cargado();
      when(
        () => repo.obtenerReporte(31),
      ).thenThrow(const ApiException.sinConexion());

      await c.cargar();

      expect(estado(c).detalle, _detalle());
      expect(estado(c).aviso, isNotNull);
    });
  });

  group('validar', () {
    test('records my vote, the new reliability and the karma notice', () async {
      final c = await cargado();
      when(
        () => repo.validar(31, TipoAccionValidacion.rechazar),
      ).thenAnswer((_) async => _voto);

      await c.validar(TipoAccionValidacion.rechazar);

      final s = estado(c);
      expect(s.detalle.miValidacion, TipoAccionValidacion.rechazar);
      expect(s.detalle.confiabilidad, _voto.confiabilidad);
      expect(s.detalle.estadoValidacion, EstadoValidacion.rechazado);
      expect(s.aviso, '¡Gracias por validar! +2 karma');
      expect(s.votando, isFalse);
    });

    test('is in flight once: a second tap is ignored', () async {
      final c = await cargado();
      final espera = Completer<ResultadoVoto>();
      when(() => repo.validar(31, any())).thenAnswer((_) => espera.future);

      final a = c.validar(TipoAccionValidacion.confirmar);
      expect(estado(c).votando, isTrue);
      final b = c.validar(TipoAccionValidacion.rechazar);
      espera.complete(_voto);
      await Future.wait([a, b]);

      verify(() => repo.validar(31, any())).called(1);
    });

    test(
      '409 says the user already took part and reloads the real vote',
      () async {
        final c = await cargado();
        when(
          () => repo.validar(31, any()),
        ).thenThrow(_api(409, 'VALIDACION_DUPLICADA'));
        when(
          () => repo.obtenerReporte(31),
        ).thenAnswer((_) async => _detalle(miValidacion: 'CONFIRMAR'));

        await c.validar(TipoAccionValidacion.rechazar);

        final s = estado(c);
        expect(s.aviso, DetalleReporteCubit.mensajeYaParticipo);
        expect(s.detalle.miValidacion, TipoAccionValidacion.confirmar);
      },
    );

    test('another failure keeps the detail with the message', () async {
      final c = await cargado();
      when(
        () => repo.validar(31, any()),
      ).thenThrow(_api(422, 'AUTOVALIDACION_NO_PERMITIDA', 'Es tu reporte'));

      await c.validar(TipoAccionValidacion.confirmar);

      expect(estado(c).aviso, 'Es tu reporte');
      expect(estado(c).detalle.miValidacion, isNull);
      expect(estado(c).votando, isFalse);
    });

    test('own reports and already voted reports cannot be voted', () async {
      final propio = await cargado(_detalle(esPropio: true));
      await propio.validar(TipoAccionValidacion.confirmar);
      final votado = await cargado(_detalle(miValidacion: 'CONFIRMAR'));
      await votado.validar(TipoAccionValidacion.rechazar);

      verifyNever(() => repo.validar(any(), any()));
    });

    test('closing while the vote is in flight does not emit', () async {
      final c = await cargado();
      final espera = Completer<ResultadoVoto>();
      when(() => repo.validar(31, any())).thenAnswer((_) => espera.future);

      final f = c.validar(TipoAccionValidacion.confirmar);
      await c.close();
      espera.complete(_voto);

      await expectLater(f, completes);
    });
  });

  test('descartarAviso clears the notice', () async {
    final c = await cargado();
    when(() => repo.validar(31, any())).thenThrow(_api(500, 'X', 'falló'));
    await c.validar(TipoAccionValidacion.confirmar);

    c.descartarAviso();

    expect(estado(c).aviso, isNull);
  });

  group('common errors', () {
    testErroresComunes('a failed first load ends as DetalleError', (
      caso,
    ) async {
      when(() => repo.obtenerReporte(31)).thenThrow(caso.error);
      final c = DetalleReporteCubit(repo, 31);

      await c.cargar();

      expect(
        c.state,
        DetalleError(
          caso.mensaje,
          codigo: caso.error.code,
          esSinConexion: caso.esSinConexion,
        ),
      );
      await c.close();
    });

    testErroresComunes('a failed vote keeps the detail unvoted with a notice', (
      caso,
    ) async {
      final c = await cargado();
      when(() => repo.validar(31, any())).thenThrow(caso.error);

      await c.validar(TipoAccionValidacion.confirmar);

      expect(c.state, DetalleCargado(_detalle(), aviso: caso.mensaje));
      await c.close();
    });
  });
}
