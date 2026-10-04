import 'package:crowdradar/app/fakes/comportamiento_fake.dart';
import 'package:crowdradar/app/fakes/karma_fake.dart';
import 'package:crowdradar/app/fakes/validacion_repository_fake.dart';
import 'package:crowdradar/core/models/validacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/session/session_service.dart';
import 'package:flutter_test/flutter_test.dart';

Matcher _falla(int status, String code) => throwsA(
  isA<ApiException>()
      .having((e) => e.status, 'status', status)
      .having((e) => e.code, 'code', code),
);

void main() {
  late SessionService sesion;
  late KarmaFake karma;
  late ValidacionRepositoryFake repo;

  setUp(() {
    sesion = SessionService.instance..reiniciar();
    karma = KarmaFake(100);
    repo = ValidacionRepositoryFake(karma: karma);
  });
  tearDown(() => sesion.reiniciar());

  Future<List<int>> ids() async => [
    for (final r in (await repo.pendientes(lat: 0, lng: 0)).items) r.id,
  ];

  test('pendientes hide my own reports and the ones I voted', () async {
    final antes = await ids();
    expect(antes, isNotEmpty);

    await repo.validar(antes.first, TipoAccionValidacion.confirmar);

    final despues = await ids();
    expect(despues, isNot(contains(antes.first)));
    expect(despues.length, antes.length - 1);
  });

  test('validar grants +2 karma and updates counts and my vote', () async {
    final id = (await ids()).first;
    final antes = await repo.obtenerReporte(id);

    final voto = await repo.validar(id, TipoAccionValidacion.rechazar);

    expect(voto.puntosGanados, 2);
    expect(voto.totalKarma, 102);
    expect(karma.total, 102);
    expect(voto.confiabilidad.rechazos, antes.confiabilidad.rechazos + 1);
    final despues = await repo.obtenerReporte(id);
    expect(despues.miValidacion, TipoAccionValidacion.rechazar);
    expect(despues.confiabilidad, voto.confiabilidad);
  });

  test('a repeated vote is 409 and grants nothing', () async {
    final id = (await ids()).first;
    await repo.validar(id, TipoAccionValidacion.confirmar);

    await expectLater(
      repo.validar(id, TipoAccionValidacion.confirmar),
      _falla(409, 'VALIDACION_DUPLICADA'),
    );
    expect(karma.total, 102);
  });

  test(
    'my own report: 422 on vote and on denuncia, esPropio in detail',
    () async {
      final propio = ValidacionRepositoryFake.idReportePropio;

      expect(await ids(), isNot(contains(propio)));
      expect((await repo.obtenerReporte(propio)).esPropio, isTrue);
      await expectLater(
        repo.validar(propio, TipoAccionValidacion.confirmar),
        _falla(422, 'AUTOVALIDACION_NO_PERMITIDA'),
      );
      await expectLater(
        repo.denunciar(propio, MotivoDenuncia.spam),
        _falla(422, 'AUTODENUNCIA_NO_PERMITIDA'),
      );
    },
  );

  test('a missing report is 404 everywhere', () async {
    await expectLater(
      repo.obtenerReporte(9999),
      _falla(404, 'REPORTE_NO_ENCONTRADO'),
    );
    await expectLater(
      repo.validar(9999, TipoAccionValidacion.confirmar),
      _falla(404, 'REPORTE_NO_ENCONTRADO'),
    );
    await expectLater(
      repo.confiabilidad(9999),
      _falla(404, 'REPORTE_NO_ENCONTRADO'),
    );
  });

  test('confiabilidad levels follow the backend thresholds', () async {
    final niveles = {
      for (final id in [101, 102, 104])
        id: (await repo.confiabilidad(id)).nivel,
    };

    expect(niveles.values.toSet(), {
      NivelConfiabilidad.alta,
      NivelConfiabilidad.insuficiente,
      NivelConfiabilidad.baja,
    });
    final baja = await repo.confiabilidad(104);
    expect(baja.advertencia, isNotNull);
    expect((await repo.confiabilidad(102)).porcentaje, isNull);
  });

  test('denunciar rejects duplicates and "otro" without detail', () async {
    final id = (await ids()).first;

    await expectLater(
      repo.denunciar(id, MotivoDenuncia.otro),
      _falla(400, 'VALIDACION_FALLIDA'),
    );
    await repo.denunciar(id, MotivoDenuncia.spam);
    await expectLater(
      repo.denunciar(id, MotivoDenuncia.spam),
      _falla(409, 'DENUNCIA_DUPLICADA'),
    );
    expect((await repo.obtenerReporte(id)).yaDenunciado, isTrue);
  });

  test('estadoMisReportes lists my reports with their estado', () async {
    final pagina = await repo.estadoMisReportes();

    expect(
      pagina.items.single.reporteId,
      ValidacionRepositoryFake.idReportePropio,
    );
  });

  test(
    'with a session service, every call needs a signed-in session',
    () async {
      final protegido = ValidacionRepositoryFake(sesion: sesion);

      await expectLater(
        protegido.pendientes(lat: 0, lng: 0),
        _falla(401, 'NO_AUTENTICADO'),
      );
      await expectLater(
        protegido.validar(101, TipoAccionValidacion.confirmar),
        _falla(401, 'NO_AUTENTICADO'),
      );
    },
  );

  test('ComportamientoFake failures propagate', () async {
    final caido = ValidacionRepositoryFake(
      comportamiento: const ComportamientoFake(
        fallo: ApiException.sinConexion(),
      ),
    );

    await expectLater(
      caido.validar(101, TipoAccionValidacion.confirmar),
      throwsA(isA<ApiException>()),
    );
  });
}
