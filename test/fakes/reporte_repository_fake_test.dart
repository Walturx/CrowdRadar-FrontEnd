import 'package:crowdradar/app/fakes/karma_fake.dart';
import 'package:crowdradar/app/fakes/reporte_repository_fake.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';

Matcher _falla(int status, String code) => throwsA(
  isA<ApiException>()
      .having((e) => e.status, 'status', status)
      .having((e) => e.code, 'code', code),
);

void main() {
  late DateTime ahora;
  late KarmaFake karma;
  late ReporteRepositoryFake repo;

  setUp(() {
    ahora = DateTime.utc(2026, 10, 5, 15);
    karma = KarmaFake(100);
    repo = ReporteRepositoryFake(karma: karma, reloj: () => ahora);
  });

  group('cooldown', () {
    test('blocks the same place at 29:59 and allows it at 30:00', () async {
      await repo.reportar(1, NivelSaturacion.moderado);

      ahora = ahora.add(const Duration(minutes: 29, seconds: 59));
      await expectLater(
        repo.reportar(1, NivelSaturacion.saturado),
        _falla(422, 'REPORTE_EN_ESPERA'),
      );

      ahora = DateTime.utc(2026, 10, 5, 15, 30);
      final r = await repo.reportar(1, NivelSaturacion.saturado);
      expect(r.reporte.nivel, NivelSaturacion.saturado);
    });

    test('the 422 message says how many minutes are left', () async {
      await repo.reportar(1, NivelSaturacion.moderado);

      ahora = ahora.add(const Duration(minutes: 10));
      await expectLater(
        repo.reportar(1, NivelSaturacion.saturado),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('vuelve a intentarlo en 20 minutos'),
          ),
        ),
      );

      ahora = DateTime.utc(2026, 10, 5, 15, 29, 30);
      await expectLater(
        repo.reportar(1, NivelSaturacion.saturado),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('en 1 minuto.'),
          ),
        ),
      );
    });

    test('another place is not affected', () async {
      await repo.reportar(1, NivelSaturacion.moderado);

      await expectLater(repo.reportar(2, NivelSaturacion.moderado), completes);
    });

    test('unknown place is a 404 and writes nothing', () async {
      await expectLater(
        repo.reportar(9999, NivelSaturacion.moderado),
        _falla(404, 'LUGAR_NO_ENCONTRADO'),
      );
      expect((await repo.listarMios()).items, isEmpty);
      expect(karma.total, 100);
    });
  });

  group('karma', () {
    test('awards +10 per report and keeps a running total', () async {
      final a = await repo.reportar(1, NivelSaturacion.moderado);
      final b = await repo.reportar(2, NivelSaturacion.moderado);

      expect(a.puntosGanados, 10);
      expect(a.totalKarma, 110);
      expect(b.totalKarma, 120);
      expect(karma.total, 120);
    });

    test(
      'the 6th report of the day earns 0 with TOPE_DIARIO, next day earns',
      () async {
        for (var lugar = 1; lugar <= 5; lugar++) {
          await repo.reportar(lugar, NivelSaturacion.moderado);
        }

        final sexto = await repo.reportar(6, NivelSaturacion.moderado);
        expect(sexto.puntosGanados, 0);
        expect(sexto.motivoSinPuntos, 'TOPE_DIARIO');
        expect(sexto.totalKarma, 150);

        ahora = ahora.add(const Duration(days: 1));
        final siguiente = await repo.reportar(7, NivelSaturacion.moderado);
        expect(siguiente.puntosGanados, 10);
        expect(siguiente.totalKarma, 160);
      },
    );
  });

  group('listarMios', () {
    test('lists newest first with place name, points and reason', () async {
      for (var lugar = 1; lugar <= 6; lugar++) {
        ahora = ahora.add(const Duration(minutes: 1));
        await repo.reportar(lugar, NivelSaturacion.saturado);
      }

      final p = await repo.listarMios(size: 2);

      expect(p.total, 6);
      expect(p.items.first.lugarId, 6);
      expect(p.items.first.lugarNombre, isNotEmpty);
      expect(p.items.first.puntosOtorgados, 0);
      expect(p.items.first.motivoSinPuntos, 'TOPE_DIARIO');
      expect(p.items.last.puntosOtorgados, 10);
      expect(p.items.first.estado, 'ACTIVO');
      expect(p.hayMas, isTrue);
    });

    test('an account without reports gets an empty page', () async {
      final p = await repo.listarMios();

      expect(p.items, isEmpty);
      expect(p.hayMas, isFalse);
    });
  });
}
