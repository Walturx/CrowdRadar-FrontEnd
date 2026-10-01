import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/models/reporte_saturacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/features/reportes/data/reporte_repository.dart';
import 'package:crowdradar/features/reportes/reportar/reportar_cubit.dart';
import 'package:crowdradar/features/reportes/reportar/reportar_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements ReporteRepository {}

ReporteCreado _creado({int puntos = 10, String? motivo}) => ReporteCreado(
  reporte: const ReporteSaturacion(
    id: 1,
    lugarId: 7,
    nivel: NivelSaturacion.moderado,
  ),
  puntosGanados: puntos,
  totalKarma: 120,
  motivoSinPuntos: motivo,
);

void main() {
  late _MockRepo repo;

  setUpAll(() => registerFallbackValue(NivelSaturacion.moderado));
  setUp(() => repo = _MockRepo());

  ReportarCubit cubit() => ReportarCubit(repo, 7);

  blocTest<ReportarCubit, ReportarState>(
    'seleccionarNivel moves to Editando(nivel)',
    build: cubit,
    act: (c) => c.seleccionarNivel(NivelSaturacion.saturado),
    expect: () => [const ReportarEditando(nivel: NivelSaturacion.saturado)],
  );

  blocTest<ReportarCubit, ReportarState>(
    'seleccionarNivel replaces a previous choice',
    build: cubit,
    act: (c) => c
      ..seleccionarNivel(NivelSaturacion.saturado)
      ..seleccionarNivel(NivelSaturacion.tranquilo),
    expect: () => [
      const ReportarEditando(nivel: NivelSaturacion.saturado),
      const ReportarEditando(nivel: NivelSaturacion.tranquilo),
    ],
  );

  blocTest<ReportarCubit, ReportarState>(
    'enviar without a level shows the HU 4.1 validation and never calls',
    build: cubit,
    act: (c) => c.enviar(),
    expect: () => [
      const ReportarEditando(
        error: 'Selecciona un nivel de saturación para enviar tu reporte.',
      ),
    ],
    verify: (_) => verifyNever(() => repo.reportar(any(), any())),
  );

  blocTest<ReportarCubit, ReportarState>(
    'enviar sends the chosen level and ends in Enviado with the karma earned',
    setUp: () => when(
      () => repo.reportar(7, NivelSaturacion.moderado),
    ).thenAnswer((_) async => _creado()),
    build: cubit,
    act: (c) => c
      ..seleccionarNivel(NivelSaturacion.moderado)
      ..enviar(),
    expect: () => [
      const ReportarEditando(nivel: NivelSaturacion.moderado),
      const ReportarEnviando(NivelSaturacion.moderado),
      const ReportarEnviado(
        mensaje: '¡Gracias por reportar!',
        puntosGanados: 10,
        totalKarma: 120,
      ),
    ],
  );

  blocTest<ReportarCubit, ReportarState>(
    'enviar with the daily cap reaches Enviado with 0 points and the reason',
    setUp: () => when(
      () => repo.reportar(7, NivelSaturacion.saturado),
    ).thenAnswer((_) async => _creado(puntos: 0, motivo: 'TOPE_DIARIO')),
    build: cubit,
    act: (c) => c
      ..seleccionarNivel(NivelSaturacion.saturado)
      ..enviar(),
    skip: 2,
    expect: () => [
      const ReportarEnviado(
        mensaje: '¡Gracias por reportar!',
        puntosGanados: 0,
        totalKarma: 120,
        motivoSinPuntos:
            'No se otorgaron puntos por este reporte (tope diario alcanzado).',
      ),
    ],
  );

  blocTest<ReportarCubit, ReportarState>(
    'cooldown 422 REPORTE_EN_ESPERA becomes the HU 4.1 message',
    setUp: () => when(() => repo.reportar(any(), any())).thenThrow(
      const ApiException(
        status: 422,
        message: 'raw backend text',
        code: 'REPORTE_EN_ESPERA',
      ),
    ),
    build: cubit,
    act: (c) => c
      ..seleccionarNivel(NivelSaturacion.moderado)
      ..enviar(),
    skip: 2,
    expect: () => [
      const ReportarFallido(
        'Ya enviaste un reporte para este lugar. Inténtalo más tarde.',
        nivel: NivelSaturacion.moderado,
        codigo: 'REPORTE_EN_ESPERA',
      ),
    ],
  );

  blocTest<ReportarCubit, ReportarState>(
    'a network failure is Fallido(esSinConexion) and can be retried',
    setUp: () {
      var llamadas = 0;
      when(() => repo.reportar(any(), any())).thenAnswer((_) async {
        if (llamadas++ == 0) throw const ApiException.sinConexion();
        return _creado();
      });
    },
    build: cubit,
    act: (c) async {
      c.seleccionarNivel(NivelSaturacion.moderado);
      await c.enviar();
      await c.enviar();
    },
    skip: 2,
    expect: () => [
      const ReportarFallido(
        ApiException.mensajeSinConexion,
        nivel: NivelSaturacion.moderado,
        esSinConexion: true,
      ),
      const ReportarEnviando(NivelSaturacion.moderado),
      const ReportarEnviado(
        mensaje: '¡Gracias por reportar!',
        puntosGanados: 10,
        totalKarma: 120,
      ),
    ],
  );

  test('a second enviar while Enviando is ignored (double tap)', () async {
    final respuesta = Completer<ReporteCreado>();
    when(() => repo.reportar(any(), any())).thenAnswer((_) => respuesta.future);
    final c = cubit()..seleccionarNivel(NivelSaturacion.tranquilo);

    final primero = c.enviar();
    await c.enviar();
    respuesta.complete(_creado());
    await primero;

    verify(() => repo.reportar(7, NivelSaturacion.tranquilo)).called(1);
    expect(c.state, isA<ReportarEnviado>());
  });

  test('seleccionarNivel is ignored once the report was sent', () async {
    when(() => repo.reportar(any(), any())).thenAnswer((_) async => _creado());
    final c = cubit()..seleccionarNivel(NivelSaturacion.moderado);
    await c.enviar();

    c.seleccionarNivel(NivelSaturacion.saturado);

    expect(c.state, isA<ReportarEnviado>());
  });
}
