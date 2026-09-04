// S6.1: USAR_FAKES=true makes every repository resolve to its Fake*.
import 'package:crowdradar/app/dependencias.dart';
import 'package:crowdradar/app/fakes/fake_analitica_repository.dart';
import 'package:crowdradar/app/fakes/fake_auth_repository.dart';
import 'package:crowdradar/app/fakes/fake_favorito_repository.dart';
import 'package:crowdradar/app/fakes/fake_lugar_repository.dart';
import 'package:crowdradar/app/fakes/fake_moderacion_repository.dart';
import 'package:crowdradar/app/fakes/fake_perfil_repository.dart';
import 'package:crowdradar/app/fakes/fake_reporte_repository.dart';
import 'package:crowdradar/app/fakes/fake_validacion_repository.dart';
import 'package:crowdradar/core/config/entorno.dart';
import 'package:crowdradar/core/session/session_service.dart';
import 'package:crowdradar/features/auth/data/auth_repository_http.dart';
import 'package:crowdradar/features/lugares/data/lugar_repository_http.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => SessionService.instance.reiniciar());

  test('S6.1 usarFakes=true injects every Fake*', () {
    final d = Dependencias.crear(
      const Entorno(usarFakes: true),
      SessionService.instance,
    );

    expect(d.authRepository, isA<FakeAuthRepository>());
    expect(d.perfilRepository, isA<FakePerfilRepository>());
    expect(d.lugarRepository, isA<FakeLugarRepository>());
    expect(d.reporteRepository, isA<FakeReporteRepository>());
    expect(d.analiticaRepository, isA<FakeAnaliticaRepository>());
    expect(d.validacionRepository, isA<FakeValidacionRepository>());
    expect(d.favoritoRepository, isA<FakeFavoritoRepository>());
    expect(d.moderacionRepository, isA<FakeModeracionRepository>());
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
      isA<FakeAuthRepository>(),
    );
  });
}
