// S9.2: each in-memory fake implements its frozen interface and behaves like
// the API contract for its main success and failure paths.
import 'package:crowdradar/app/fakes/comportamiento_fake.dart';
import 'package:crowdradar/app/fakes/datos_fake.dart';
import 'package:crowdradar/app/fakes/analitica_repository_fake.dart';
import 'package:crowdradar/app/fakes/auth_repository_fake.dart';
import 'package:crowdradar/app/fakes/favorito_repository_fake.dart';
import 'package:crowdradar/app/fakes/lugar_repository_fake.dart';
import 'package:crowdradar/app/fakes/moderacion_repository_fake.dart';
import 'package:crowdradar/app/fakes/perfil_repository_fake.dart';
import 'package:crowdradar/app/fakes/reporte_repository_fake.dart';
import 'package:crowdradar/app/fakes/validacion_repository_fake.dart';
import 'package:crowdradar/core/models/moderacion.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/session/session_service.dart';
import 'package:crowdradar/core/session/usuario_sesion.dart';
import 'package:crowdradar/features/analitica/data/analitica_repository.dart';
import 'package:crowdradar/features/auth/data/auth_repository.dart';
import 'package:crowdradar/features/favoritos/data/favorito_repository.dart';
import 'package:crowdradar/features/moderacion/data/moderacion_repository.dart';
import 'package:crowdradar/features/perfil/data/perfil_repository.dart';
import 'package:crowdradar/features/reportes/data/reporte_repository.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

Matcher _falla(int status, String code) => throwsA(
  isA<ApiException>()
      .having((e) => e.status, 'status', status)
      .having((e) => e.code, 'code', code),
);

void main() {
  late SessionService sesion;
  setUp(() => sesion = SessionService.instance..reiniciar());
  tearDown(() => sesion.reiniciar());

  group('AuthRepositoryFake', () {
    test('valid credentials start the session', () async {
      final AuthRepository repo = AuthRepositoryFake(sesion);

      final user = await repo.iniciarSesion('ana@test.com', 'Secreta1');

      expect(user.email, 'ana@test.com');
      expect(sesion.usuario?.email, 'ana@test.com');
      expect(sesion.token, isNotNull);
    });

    test('wrong password is a 401 and leaves the session closed', () async {
      final repo = AuthRepositoryFake(sesion);

      await expectLater(
        repo.iniciarSesion('ana@test.com', 'mala'),
        _falla(401, 'CREDENCIALES_INVALIDAS'),
      );
      expect(sesion.token, isNull);
    });

    test(
      'registering an existing email is a 409, a new one succeeds',
      () async {
        final repo = AuthRepositoryFake(sesion);
        Future<Object?> registrar(String email) => repo.registrar(
          nombre: 'Luz',
          apellido: 'Vega',
          email: email,
          password: 'Secreta1',
          telefono: '',
          distrito: 'Lima',
        );

        await expectLater(
          registrar('ana@test.com'),
          _falla(409, 'EMAIL_DUPLICADO'),
        );
        expect(
          (await repo.registrar(
            nombre: 'Luz',
            apellido: 'Vega',
            email: 'luz@test.com',
            password: 'Secreta1',
            telefono: '',
            distrito: 'Lima',
          )).email,
          'luz@test.com',
        );
        await expectLater(
          registrar('luz@test.com'),
          _falla(409, 'EMAIL_DUPLICADO'),
        );
        await expectLater(repo.solicitarRecuperacion('x@y.z'), completes);
      },
    );
  });

  group('PerfilRepositoryFake', () {
    test('without session it reports "No hay sesión activa"', () async {
      final PerfilRepository repo = PerfilRepositoryFake(sesion);

      await expectLater(repo.obtener(), _falla(401, 'NO_AUTENTICADO'));
    });

    test('obtener and actualizar follow the session user', () async {
      await AuthRepositoryFake(
        sesion,
      ).iniciarSesion('ana@test.com', 'Secreta1');
      final repo = PerfilRepositoryFake(sesion);

      expect((await repo.obtener()).nombre, 'Ana');
      final editado = await repo.actualizar({'nombre': 'Beatriz'});

      expect(editado.nombre, 'Beatriz');
      expect((await repo.obtener()).nombre, 'Beatriz');
      expect(sesion.usuario?.nombre, 'Beatriz');
    });

    test('cambiarPassword validates current and repeated passwords', () async {
      await AuthRepositoryFake(
        sesion,
      ).iniciarSesion('ana@test.com', 'Secreta1');
      final repo = PerfilRepositoryFake(sesion);

      await expectLater(
        repo.cambiarPassword(
          actual: 'mala',
          nueva: 'Nueva1aa',
          confirmar: 'Nueva1aa',
        ),
        _falla(422, 'PASSWORD_ACTUAL_INCORRECTA'),
      );
      await expectLater(
        repo.cambiarPassword(
          actual: 'Secreta1',
          nueva: 'Secreta1',
          confirmar: 'Secreta1',
        ),
        _falla(422, 'PASSWORD_REPETIDA'),
      );
      await expectLater(
        repo.cambiarPassword(
          actual: 'Secreta1',
          nueva: 'Nueva1aa',
          confirmar: 'Nueva1aa',
        ),
        completes,
      );
    });
  });

  group('ReporteRepositoryFake', () {
    test('reportar awards karma and enforces the cooldown per place', () async {
      final ReporteRepository repo = ReporteRepositoryFake();

      final primero = await repo.reportar(1, NivelSaturacion.saturado);
      final otroLugar = await repo.reportar(2, NivelSaturacion.tranquilo);

      expect(primero.puntosGanados, 10);
      expect(otroLugar.totalKarma, primero.totalKarma + 10);
      await expectLater(
        repo.reportar(1, NivelSaturacion.moderado),
        _falla(422, 'REPORTE_EN_ESPERA'),
      );
    });

    test('listarMios paginates what was reported', () async {
      final repo = ReporteRepositoryFake();
      await repo.reportar(1, NivelSaturacion.saturado);
      await repo.reportar(2, NivelSaturacion.tranquilo);

      final p1 = await repo.listarMios(size: 1);
      final p2 = await repo.listarMios(page: 2, size: 1);

      expect(p1.items, hasLength(1));
      expect(p1.total, 2);
      expect(p1.hayMas, isTrue);
      expect(p2.items, hasLength(1));
      expect(p2.hayMas, isFalse);
    });
  });

  group('AnaliticaRepositoryFake', () {
    final AnaliticaRepository repo = AnaliticaRepositoryFake();
    final d = DateTime.utc(2026, 10, 1);

    test('known places return data for every query', () async {
      expect((await repo.historial(1)).puntos, isNotEmpty);
      expect((await repo.mejorHorario(1)).franjas, isNotEmpty);
      final c = await repo.comparar(
        1,
        desdeA: d,
        hastaA: d,
        desdeB: d,
        hastaB: d,
      );
      expect(c.periodoA.puntos, isNotEmpty);
      expect(c.periodoB.puntos, isNotEmpty);
    });

    test('places without history answer 200 with sinDatos', () async {
      expect((await repo.historial(9999)).sinDatos, isTrue);
      expect((await repo.mejorHorario(9999)).sinDatos, isTrue);
    });
  });

  group('FavoritoRepositoryFake', () {
    test('starts empty with an explanatory message', () async {
      final FavoritoRepository repo = FavoritoRepositoryFake();

      final r = await repo.listar();

      expect(r.estaVacia, isTrue);
      expect(r.mensaje, isNotEmpty);
    });

    test('agregar, duplicate, alertas and eliminar', () async {
      final repo = FavoritoRepositoryFake();

      await repo.agregar(1);
      await expectLater(repo.agregar(1), _falla(409, 'FAVORITO_DUPLICADO'));
      await repo.configurarAlertas(1, activadas: true);
      expect((await repo.listar()).items.single.alertasActivadas, isTrue);

      await repo.eliminar(1);
      expect((await repo.listar()).estaVacia, isTrue);
      await expectLater(
        repo.eliminar(1),
        _falla(404, 'FAVORITO_NO_ENCONTRADO'),
      );
    });
  });

  group('ModeracionRepositoryFake', () {
    test(
      'resolver removes the report from the queue and reports the estado',
      () async {
        final ModeracionRepository repo = ModeracionRepositoryFake();
        final antes = await repo.reportesDenunciados();
        final id = antes.items.first.reporteId;

        final res = await repo.resolver(id, DecisionModeracion.eliminar);

        expect(res.estado, EstadoReporteModerado.eliminado);
        expect(res.denunciasResueltas, antes.items.first.pendientes);
        expect((await repo.reportesDenunciados()).total, antes.total - 1);
        await expectLater(
          repo.resolver(id, DecisionModeracion.mantener),
          _falla(409, 'SIN_DENUNCIAS_PENDIENTES'),
        );
        await expectLater(
          repo.reporteDenunciado(id),
          _falla(404, 'REPORTE_NO_ENCONTRADO'),
        );
      },
    );

    test('mantener keeps the report ACTIVO', () async {
      final repo = ModeracionRepositoryFake();
      final id = (await repo.reportesDenunciados()).items.first.reporteId;

      final res = await repo.resolver(id, DecisionModeracion.mantener);

      expect(res.estado, EstadoReporteModerado.activo);
    });

    test('reporteDenunciado returns motivos and the author email', () async {
      final repo = ModeracionRepositoryFake();
      final id = (await repo.reportesDenunciados()).items.first.reporteId;

      final d = await repo.reporteDenunciado(id);

      expect(d.motivos, isNotEmpty);
      expect(d.autor.email, isNotNull);
    });

    test('usuarios filters by text and status and sorts', () async {
      final repo = ModeracionRepositoryFake();

      final todos = await repo.usuarios();
      final activos = await repo.usuarios(status: EstadoCuenta.activo);
      final busqueda = await repo.usuarios(q: todos.items.first.nombre);
      final porKarma = await repo.usuarios(orden: OrdenUsuarios.karma);

      expect(activos.items.every((u) => !u.estaSuspendido), isTrue);
      expect(busqueda.items, isNotEmpty);
      expect(busqueda.items.length, lessThanOrEqualTo(todos.items.length));
      final karmas = porKarma.items.map((u) => u.puntosKarma).toList();
      expect(karmas, [...karmas]..sort((a, b) => b.compareTo(a)));
    });

    test('a suspended fake user carries the sancion with fechaFin', () async {
      final repo = ModeracionRepositoryFake();

      final s = (await repo.usuarios(status: EstadoCuenta.suspendido)).items;

      expect(s, isNotEmpty);
      expect(s.first.sancionVigente!.fechaFin, isNotNull);
    });

    test(
      'suspender and reactivar toggle the account with 409 on repeats',
      () async {
        final repo = ModeracionRepositoryFake();
        final id = (await repo.usuarios(
          status: EstadoCuenta.activo,
        )).items.first.id;

        await expectLater(
          repo.reactivar(id),
          _falla(409, 'USUARIO_NO_SUSPENDIDO'),
        );
        final sancion = await repo.suspender(
          id,
          dias: 3,
          motivo: 'Spam reiterado',
        );
        expect(sancion.dias, 3);
        final detalle = await repo.usuario(id);
        expect(detalle.estaSuspendido, isTrue);
        expect(detalle.sancionVigente!.motivo, 'Spam reiterado');
        await expectLater(
          repo.suspender(id, dias: 7, motivo: 'Spam reiterado'),
          _falla(409, 'USUARIO_YA_SUSPENDIDO'),
        );

        await repo.reactivar(id);
        final despues = await repo.usuario(id);
        expect(despues.estaSuspendido, isFalse);
        expect(despues.sancionVigente, isNull);
        await expectLater(
          repo.usuario(9999),
          _falla(404, 'USUARIO_NO_ENCONTRADO'),
        );
      },
    );

    test('suspender rejects an ADMIN and a dias outside 3/7/30', () async {
      final repo = ModeracionRepositoryFake();
      final admin = (await repo.usuarios()).items.firstWhere((u) => u.esAdmin);
      final id = (await repo.usuarios(
        status: EstadoCuenta.activo,
      )).items.firstWhere((u) => !u.esAdmin).id;

      await expectLater(
        repo.suspender(admin.id, dias: 3, motivo: 'Spam reiterado'),
        _falla(422, 'OPERACION_NO_PERMITIDA'),
      );
      await expectLater(
        repo.suspender(id, dias: 5, motivo: 'Spam reiterado'),
        _falla(400, 'VALIDACION_FALLIDA'),
      );
    });

    test('with a session service it needs an admin (401 / 403)', () async {
      final sesion = SessionService.instance..reiniciar();
      final repo = ModeracionRepositoryFake(sesion: sesion);
      await expectLater(repo.usuarios(), _falla(401, 'NO_AUTENTICADO'));

      await sesion.iniciar(
        'token-fake',
        UsuarioSesion.desdeUsuario(usuarioFake),
      );
      await expectLater(repo.usuarios(), _falla(403, 'ACCESO_DENEGADO'));
      await expectLater(
        repo.reportesDenunciados(),
        _falla(403, 'ACCESO_DENEGADO'),
      );

      await sesion.iniciar(
        'token-fake',
        UsuarioSesion.desdeUsuario(usuarioAdminFake),
      );
      expect((await repo.usuarios()).items, isNotEmpty);
      sesion.reiniciar();
    });

    test('the admin fake credentials sign in as ADMIN', () async {
      final sesion = SessionService.instance..reiniciar();
      final usuario = await AuthRepositoryFake(
        sesion,
      ).iniciarSesion(emailAdminFake, passwordFake);

      expect(usuario.rol, 'ADMIN');
      expect(sesion.usuario!.esAdmin, isTrue);
      sesion.reiniciar();
    });
  });

  group('R3-105 paginar', () {
    final datos = [1, 2, 3, 4, 5];

    test('returns the requested 1-based page', () {
      final p = paginar(datos, 2, 2);

      expect(p.items, [3, 4]);
      expect(p.total, 5);
      expect(p.totalPaginas, 3);
    });

    test('a page past the end is empty, not an error', () {
      final p = paginar(datos, 9, 2);

      expect(p.items, isEmpty);
      expect(p.page, 9);
    });

    test('page <= 0 is a 400 PAGINACION_INVALIDA', () {
      expect(() => paginar(datos, 0, 2), _lanza400());
      expect(() => paginar(datos, -1, 2), _lanza400());
    });

    test('size <= 0 is a 400 PAGINACION_INVALIDA', () {
      expect(() => paginar(datos, 1, 0), _lanza400());
      expect(() => paginar(datos, 1, -5), _lanza400());
    });
  });

  group('R4-105 ComportamientoFake', () {
    test('a configured failure is thrown by every kind of fake', () async {
      const caido = ComportamientoFake(fallo: ApiException.sinConexion());
      final fakes = <Future<Object?> Function()>[
        () => LugarRepositoryFake(comportamiento: caido).buscar(q: 'Pa'),
        () => AuthRepositoryFake(
          sesion,
          comportamiento: caido,
        ).iniciarSesion('ana@test.com', 'Secreta1'),
        () => PerfilRepositoryFake(sesion, comportamiento: caido).obtener(),
        () => ReporteRepositoryFake(comportamiento: caido).listarMios(),
        () => AnaliticaRepositoryFake(comportamiento: caido).historial(1),
        () => ValidacionRepositoryFake(
          comportamiento: caido,
        ).pendientes(lat: 0, lng: 0),
        () => FavoritoRepositoryFake(comportamiento: caido).listar(),
        () => ModeracionRepositoryFake(comportamiento: caido).usuarios(),
      ];

      for (final llamar in fakes) {
        await expectLater(
          llamar(),
          throwsA(
            isA<ApiException>().having((e) => e.esSinConexion, 'offline', true),
          ),
        );
      }
    });

    test('the default behavior answers at once without failing', () async {
      final repo = LugarRepositoryFake();

      expect((await repo.buscar(q: 'Pa')).items, isNotEmpty);
    });

    test('latency delays the answer until the duration elapses', () {
      fakeAsync((reloj) {
        final repo = LugarRepositoryFake(
          comportamiento: const ComportamientoFake(
            latencia: Duration(seconds: 2),
          ),
        );
        var respondio = false;
        repo.buscar(q: 'Pa').then((_) => respondio = true);

        reloj.elapse(const Duration(seconds: 1));
        expect(respondio, isFalse);

        reloj.elapse(const Duration(seconds: 1));
        expect(respondio, isTrue);
      });
    });
  });
}

Matcher _lanza400() => throwsA(
  isA<ApiException>()
      .having((e) => e.status, 'status', 400)
      .having((e) => e.code, 'code', 'PAGINACION_INVALIDA'),
);
