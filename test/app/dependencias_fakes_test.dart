// S6.1: USAR_FAKES=true makes every repository resolve to its *RepositoryFake.
import 'package:crowdradar/app/dependencias.dart';
import 'package:crowdradar/app/fakes/analitica_repository_fake.dart';
import 'package:crowdradar/app/fakes/auth_repository_fake.dart';
import 'package:crowdradar/app/fakes/alerta_repository_fake.dart';
import 'package:crowdradar/app/fakes/favorito_repository_fake.dart';
import 'package:crowdradar/app/fakes/lugar_repository_fake.dart';
import 'package:crowdradar/app/fakes/moderacion_repository_fake.dart';
import 'package:crowdradar/app/fakes/perfil_repository_fake.dart';
import 'package:crowdradar/app/fakes/reporte_repository_fake.dart';
import 'package:crowdradar/app/fakes/validacion_repository_fake.dart';
import 'package:crowdradar/core/config/entorno.dart';
import 'package:crowdradar/core/session/session_service.dart';
import 'package:crowdradar/features/auth/data/auth_repository_http.dart';
import 'package:crowdradar/features/lugares/data/lugar_repository_http.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => SessionService.instance.reiniciar());

  test('S6.1 usarFakes=true injects every *RepositoryFake', () {
    final d = Dependencias.crear(
      const Entorno(usarFakes: true),
      SessionService.instance,
    );

    expect(d.authRepository, isA<AuthRepositoryFake>());
    expect(d.perfilRepository, isA<PerfilRepositoryFake>());
    expect(d.lugarRepository, isA<LugarRepositoryFake>());
    expect(d.reporteRepository, isA<ReporteRepositoryFake>());
    expect(d.analiticaRepository, isA<AnaliticaRepositoryFake>());
    expect(d.validacionRepository, isA<ValidacionRepositoryFake>());
    expect(d.favoritoRepository, isA<FavoritoRepositoryFake>());
    expect(d.alertaRepository, isA<AlertaRepositoryFake>());
    expect(d.moderacionRepository, isA<ModeracionRepositoryFake>());
  });

  test('S6.1 usarFakes=false keeps the http implementations', () {
    final d = Dependencias.crear(const Entorno(), SessionService.instance);

    expect(d.authRepository, isA<AuthRepositoryHttp>());
    expect(d.lugarRepository, isA<LugarRepositoryHttp>());
  });

  test('R1-101 fakes in a release build are refused', () {
    expect(
      () => Dependencias.crear(
        const Entorno(usarFakes: true),
        SessionService.instance,
        esRelease: true,
      ),
      throwsA(isA<StateError>().having(
          (e) => e.message, 'message', contains('USAR_FAKES'))),
    );
  });

  test('R1-101 release without fakes and non-release with fakes still work',
      () {
    expect(
      Dependencias.crear(const Entorno(), SessionService.instance,
          esRelease: true).authRepository,
      isA<AuthRepositoryHttp>(),
    );
    expect(
      Dependencias.crear(const Entorno(usarFakes: true),
          SessionService.instance, esRelease: false).authRepository,
      isA<AuthRepositoryFake>(),
    );
  });
}
