import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:crowdradar/core/models/analitica.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/features/analitica/carga/analitica_state.dart';
import 'package:crowdradar/features/analitica/comparar/comparar_periodos_cubit.dart';
import 'package:crowdradar/features/analitica/data/analitica_repository.dart';
import 'package:crowdradar/features/analitica/historial/historial_lugar_cubit.dart';
import 'package:crowdradar/features/analitica/mejor_horario/mejor_horario_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements AnaliticaRepository {}

const _serie = SerieSaturacion(puntos: [PuntoSerie('09:00', 2, muestras: 3)]);
const _sinHistorial = SerieSaturacion(
  sinDatos: true,
  mensaje: 'No existe información histórica disponible para este lugar.',
);
final _hoy = DateTime(2026, 10, 5, 15);

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
    registerFallbackValue(DateTime(2026));
  });

  group('HistorialLugarCubit', () {
    HistorialLugarCubit cubit() =>
        HistorialLugarCubit(repo, 7, reloj: () => _hoy);

    blocTest<HistorialLugarCubit, AnaliticaState<SerieSaturacion>>(
      'cargar asks for today grouped by hour and emits Cargado',
      setUp: () => when(
        () => repo.historial(
          7,
          desde: any(named: 'desde'),
          hasta: any(named: 'hasta'),
          agrupacion: AgrupacionHistorial.hora,
        ),
      ).thenAnswer((_) async => _serie),
      build: cubit,
      act: (c) => c.cargar(),
      expect: () => const [
        AnaliticaCargando<SerieSaturacion>(),
        AnaliticaCargado<SerieSaturacion>(_serie),
      ],
    );

    blocTest<HistorialLugarCubit, AnaliticaState<SerieSaturacion>>(
      'no history keeps the backend message in SinDatos (HU 6.1 c3)',
      setUp: () => when(
        () => repo.historial(
          7,
          desde: any(named: 'desde'),
          hasta: any(named: 'hasta'),
          agrupacion: any(named: 'agrupacion'),
        ),
      ).thenAnswer((_) async => _sinHistorial),
      build: cubit,
      act: (c) => c.cargar(),
      expect: () => [
        const AnaliticaCargando<SerieSaturacion>(),
        AnaliticaSinDatos<SerieSaturacion>(_sinHistorial.mensaje),
      ],
    );

    blocTest<HistorialLugarCubit, AnaliticaState<SerieSaturacion>>(
      'a failure is Error with code and offline flag; retry works',
      setUp: () {
        var n = 0;
        when(
          () => repo.historial(
            7,
            desde: any(named: 'desde'),
            hasta: any(named: 'hasta'),
            agrupacion: any(named: 'agrupacion'),
          ),
        ).thenAnswer((_) async {
          if (n++ == 0) throw const ApiException.sinConexion();
          return _serie;
        });
      },
      build: cubit,
      act: (c) async {
        await c.cargar();
        await c.cargar();
      },
      expect: () => const [
        AnaliticaCargando<SerieSaturacion>(),
        AnaliticaError<SerieSaturacion>(
          ApiException.mensajeSinConexion,
          esSinConexion: true,
        ),
        AnaliticaCargando<SerieSaturacion>(),
        AnaliticaCargado<SerieSaturacion>(_serie),
      ],
    );

    test('seleccionar(dia) reloads the last 7 days grouped by day', () async {
      when(
        () => repo.historial(
          7,
          desde: any(named: 'desde'),
          hasta: any(named: 'hasta'),
          agrupacion: any(named: 'agrupacion'),
        ),
      ).thenAnswer((_) async => _serie);
      final c = cubit();
      await c.cargar();

      await c.seleccionar(AgrupacionHistorial.dia);

      expect(c.agrupacion, AgrupacionHistorial.dia);
      verify(
        () => repo.historial(
          7,
          desde: DateTime(2026, 9, 29),
          hasta: DateTime(2026, 10, 5),
          agrupacion: AgrupacionHistorial.dia,
        ),
      ).called(1);
    });

    test('a second cargar while one is in flight is ignored', () async {
      final espera = Completer<SerieSaturacion>();
      when(
        () => repo.historial(
          7,
          desde: any(named: 'desde'),
          hasta: any(named: 'hasta'),
          agrupacion: any(named: 'agrupacion'),
        ),
      ).thenAnswer((_) => espera.future);
      final c = cubit();

      final a = c.cargar();
      await c.cargar();
      espera.complete(_serie);
      await a;

      verify(
        () => repo.historial(
          7,
          desde: any(named: 'desde'),
          hasta: any(named: 'hasta'),
          agrupacion: any(named: 'agrupacion'),
        ),
      ).called(1);
    });
  });

  group('CompararPeriodosCubit', () {
    const comparacion = ComparacionPeriodos(_serie, _serie, resumen: 'Sube');
    const insuficiente = ComparacionPeriodos(
      SerieSaturacion(sinDatos: true),
      SerieSaturacion(sinDatos: true),
      suficiente: false,
      mensaje: 'No existen datos suficientes para realizar la comparación.',
    );

    CompararPeriodosCubit cubit() =>
        CompararPeriodosCubit(repo, 7, reloj: () => _hoy);

    void stub(ComparacionPeriodos r) => when(
      () => repo.comparar(
        7,
        desdeA: any(named: 'desdeA'),
        hastaA: any(named: 'hastaA'),
        desdeB: any(named: 'desdeB'),
        hastaB: any(named: 'hastaB'),
        diasA: any(named: 'diasA'),
        diasB: any(named: 'diasB'),
      ),
    ).thenAnswer((_) async => r);

    test('compares weekdays against weekends over the last 28 days', () async {
      stub(comparacion);
      final c = cubit();

      await c.cargar();

      verify(
        () => repo.comparar(
          7,
          desdeA: DateTime(2026, 9, 8),
          hastaA: DateTime(2026, 10, 5),
          desdeB: DateTime(2026, 9, 8),
          hastaB: DateTime(2026, 10, 5),
          diasA: 'LABORABLES',
          diasB: 'FIN_DE_SEMANA',
        ),
      ).called(1);
      expect(c.state, const AnaliticaCargado<ComparacionPeriodos>(comparacion));
    });

    test('insufficient data is SinDatos with the HU 6.2 c3 message', () async {
      stub(insuficiente);
      final c = cubit();

      await c.cargar();

      expect(
        c.state,
        AnaliticaSinDatos<ComparacionPeriodos>(insuficiente.mensaje),
      );
    });

    test('a failure ends in Error', () async {
      when(
        () => repo.comparar(
          7,
          desdeA: any(named: 'desdeA'),
          hastaA: any(named: 'hastaA'),
          desdeB: any(named: 'desdeB'),
          hastaB: any(named: 'hastaB'),
          diasA: any(named: 'diasA'),
          diasB: any(named: 'diasB'),
        ),
      ).thenThrow(const ApiException(status: 500, message: 'caído'));
      final c = cubit();

      await c.cargar();

      expect(c.state, const AnaliticaError<ComparacionPeriodos>('caído'));
    });
  });

  group('MejorHorarioCubit', () {
    const mejor = MejorHorario(
      franjas: [FranjaHoraria(9, 10, NivelSaturacion.tranquilo)],
    );
    const vacio = MejorHorario(
      sinDatos: true,
      mensaje: 'No existen datos suficientes para generar la recomendación.',
    );

    test('cargar emits Cargado with the recommended slots', () async {
      when(() => repo.mejorHorario(7)).thenAnswer((_) async => mejor);
      final c = MejorHorarioCubit(repo, 7);

      await c.cargar();

      expect(c.state, const AnaliticaCargado<MejorHorario>(mejor));
    });

    test('no recommendation is SinDatos with the HU 6.3 c3 message', () async {
      when(() => repo.mejorHorario(7)).thenAnswer((_) async => vacio);
      final c = MejorHorarioCubit(repo, 7);

      await c.cargar();

      expect(c.state, AnaliticaSinDatos<MejorHorario>(vacio.mensaje));
    });

    test(
      'an empty slot list without the flag still counts as no data',
      () async {
        when(
          () => repo.mejorHorario(7),
        ).thenAnswer((_) async => const MejorHorario());
        final c = MejorHorarioCubit(repo, 7);

        await c.cargar();

        expect(c.state, isA<AnaliticaSinDatos<MejorHorario>>());
      },
    );
  });
}
