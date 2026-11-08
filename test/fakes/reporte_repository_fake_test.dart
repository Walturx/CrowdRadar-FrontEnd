import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/session/session_service.dart';
import 'package:crowdradar/core/session/usuario_sesion.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reporte_repository_fake.dart';

Matcher _falla(int status, String code) => throwsA(
  isA<ApiException>()
      .having((e) => e.status, 'status', status)
      .having((e) => e.code, 'code', code),
);

void main() {
  late DateTime ahora;
  late ReporteRepositoryFake repo;

  setUp(() {
    ahora = DateTime.utc(2026, 10, 5, 15);
    repo = ReporteRepositoryFake(reloj: () => ahora);
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
    });
  });

  group('points (C2 / C4)', () {
    test('a new report is not VALIDADO yet, so it carries 0 points', () async {
      final r = await repo.reportar(1, NivelSaturacion.moderado);

      expect(r.reporte.puntos, 0);
      expect(r.reporte.estado, 'ACTIVO');
    });

    test(
      'there is no daily cap: a sixth report the same day is accepted',
      () async {
        for (var lugar = 1; lugar <= 5; lugar++) {
          await repo.reportar(lugar, NivelSaturacion.moderado);
        }

        final sexto = await repo.reportar(6, NivelSaturacion.moderado);

        expect(sexto.reporte.lugarId, 6);
        expect((await repo.listarMios()).total, 6);
      },
    );
  });

  group('session (R4-608)', () {
    test('reportar and listarMios need a session when one is wired', () async {
      final sesion = SessionService.instance..reiniciar();
      addTearDown(sesion.reiniciar);
      final conSesion = ReporteRepositoryFake(sesion: sesion);

      await expectLater(
        conSesion.reportar(1, NivelSaturacion.moderado),
        _falla(401, 'NO_AUTENTICADO'),
      );
      await expectLater(conSesion.listarMios(), _falla(401, 'NO_AUTENTICADO'));

      await sesion.iniciar('t', const UsuarioSesion(id: 1));
      await expectLater(
        conSesion.reportar(1, NivelSaturacion.moderado),
        completes,
      );
      expect((await conSesion.listarMios()).items, hasLength(1));
    });
  });

  group('listarMios', () {
    test('lists newest first with place name, points and estado', () async {
      for (var lugar = 1; lugar <= 6; lugar++) {
        ahora = ahora.add(const Duration(minutes: 1));
        await repo.reportar(lugar, NivelSaturacion.saturado);
      }

      final p = await repo.listarMios(size: 2);

      expect(p.total, 6);
      expect(p.items.first.lugarId, 6);
      expect(p.items.first.lugarNombre, isNotEmpty);
      expect(p.items.first.puntos, 0);
      expect(p.items.last.puntos, 0);
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
