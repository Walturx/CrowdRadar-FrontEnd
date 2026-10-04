import 'package:crowdradar/app/fakes/analitica_repository_fake.dart';
import 'package:crowdradar/app/fakes/historial_sintetico.dart';
import 'package:crowdradar/core/models/analitica.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/features/analitica/analitica_parametros.dart';
import 'package:flutter_test/flutter_test.dart';

Matcher _rangoInvalido() => throwsA(
  isA<ApiException>()
      .having((e) => e.status, 'status', 400)
      .having((e) => e.code, 'code', 'RANGO_FECHAS_INVALIDO'),
);

void main() {
  group('valorSintetico', () {
    test('is deterministic per seed and stays within 1..3', () {
      for (var seed = 1; seed <= 20; seed++) {
        for (var h = 0; h < 24; h++) {
          final v = valorSintetico(seed, h);
          expect(v, valorSintetico(seed, h));
          expect(v, inInclusiveRange(1.0, 3.0));
        }
      }
    });

    test('different seeds give different series; weekends peak later', () {
      final a = [for (var h = 0; h < 24; h++) valorSintetico(1, h)];
      final b = [for (var h = 0; h < 24; h++) valorSintetico(2, h)];
      expect(a, isNot(b));

      double media(bool finde) =>
          [
            for (var h = 11; h <= 18; h++)
              valorSintetico(1, h, finDeSemana: finde),
          ].reduce((x, y) => x + y) /
          8;
      expect(media(true), greaterThan(media(false)));
    });
  });

  group('AnaliticaRepositoryFake', () {
    final repo = AnaliticaRepositoryFake();
    final inicio = DateTime(2026, 9, 1);

    test('historial by hour returns 24 labelled, flagged points', () async {
      final s = await repo.historial(1);

      expect(s.sinDatos, isFalse);
      expect(s.sintetico, isTrue);
      expect(s.puntos, hasLength(24));
      expect(s.puntos.first.etiqueta, '00:00');
      expect(s.puntos.last.etiqueta, '23:00');
      expect(s.puntos.every((p) => p.muestras > 0), isTrue);
      expect(s, await AnaliticaRepositoryFake().historial(1));
      expect((await repo.historial(2)).puntos, isNot(s.puntos));
    });

    test('historial by day yields one point per day of the range', () async {
      final s = await repo.historial(
        1,
        desde: inicio,
        hasta: DateTime(2026, 9, 7),
        agrupacion: AgrupacionHistorial.dia,
      );

      expect(s.puntos, hasLength(7));
      expect(s.puntos.first.etiqueta, '2026-09-01');
      expect(s.puntos.last.etiqueta, '2026-09-07');
    });

    test('the daily default window follows the injected clock', () async {
      final fijo = AnaliticaRepositoryFake(
        reloj: () => DateTime(2026, 9, 7, 15),
      );

      final s = await fijo.historial(1, agrupacion: AgrupacionHistorial.dia);

      expect(s.puntos, hasLength(AnaliticaParametros.diasHistorialCorto));
      expect(s.puntos.first.etiqueta, '2026-09-01');
      expect(s.puntos.last.etiqueta, '2026-09-07');
    });

    test('the same day of another year gets another series', () async {
      Future<List<double>> valores(int anio) async {
        final repo = AnaliticaRepositoryFake(reloj: () => DateTime(anio, 9, 7));
        final s = await repo.historial(1, agrupacion: AgrupacionHistorial.dia);
        return [for (final p in s.puntos) p.valor];
      }

      expect(await valores(2026), await valores(2026));
      expect(await valores(2026), isNot(await valores(2027)));
    });

    test('invalid ranges are a 400 RANGO_FECHAS_INVALIDO', () async {
      await expectLater(
        repo.historial(1, desde: inicio, hasta: inicio),
        _rangoInvalido(),
      );
      await expectLater(
        repo.historial(1, desde: inicio, hasta: DateTime(2026, 10, 3)),
        _rangoInvalido(),
      );
    });

    test(
      'places without history answer 200 with sinDatos and the HU message',
      () async {
        final s = await repo.historial(9999);

        expect(s.sinDatos, isTrue);
        expect(s.mensaje, contains('No existe información histórica'));
        expect((await repo.mejorHorario(9999)).sinDatos, isTrue);
      },
    );

    test('comparar returns 24 slots, differences and a summary', () async {
      final c = await repo.comparar(
        1,
        desdeA: inicio,
        hastaA: DateTime(2026, 9, 15),
        diasA: 'LABORABLES',
        desdeB: inicio,
        hastaB: DateTime(2026, 9, 15),
        diasB: 'FIN_DE_SEMANA',
      );

      expect(c.sinDatos, isFalse);
      expect(c.sintetico, isTrue);
      expect(c.periodoA.puntos, hasLength(24));
      expect(c.periodoB.puntos, hasLength(24));
      expect(c.diferencias, hasLength(24));
      expect(
        c.diferencias[12].diferencia,
        closeTo(
          c.periodoB.puntos[12].valor - c.periodoA.puntos[12].valor,
          1e-9,
        ),
      );
      expect(c.resumen, isNotEmpty);
    });

    test('comparar for an unknown place is insufficient data', () async {
      final c = await repo.comparar(
        9999,
        desdeA: inicio,
        hastaA: DateTime(2026, 9, 15),
        desdeB: inicio,
        hastaB: DateTime(2026, 9, 15),
      );

      expect(c.sinDatos, isTrue);
      expect(c.mensaje, contains('datos suficientes'));
    });

    test(
      'mejorHorario gives up to 3 opening-hour slots, calmest first',
      () async {
        final m = await repo.mejorHorario(1);

        expect(m.sinDatos, isFalse);
        expect(m.sintetico, isTrue);
        expect(m.franjas, hasLength(3));
        expect(
          m.franjas.every((f) => f.horaInicio >= 8 && f.horaFin <= 22),
          isTrue,
        );
        final promedios = m.franjas.map((f) => f.promedio!).toList();
        expect(promedios, [...promedios]..sort());
        expect(m.franjas.every((f) => f.horaFin == f.horaInicio + 1), isTrue);
      },
    );
  });
}
