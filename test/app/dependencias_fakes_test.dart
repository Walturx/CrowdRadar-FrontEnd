// S6.1: USAR_FAKES=true makes every repository resolve to its *RepositoryFake.
import 'package:crowdradar/app/dependencias.dart';
import 'package:crowdradar/app/fabrica_repositorios.dart';
import 'package:crowdradar/app/fakes/analitica_repository_fake.dart';
import 'package:crowdradar/app/fakes/auth_repository_fake.dart';
import 'package:crowdradar/app/fakes/alerta_repository_fake.dart';
import 'package:crowdradar/app/fakes/exploracion_repository_fake.dart';
import 'package:crowdradar/app/fakes/fabrica_repositorios_fake.dart';
import 'package:crowdradar/app/fakes/favorito_repository_fake.dart';
import 'package:crowdradar/app/fakes/lugar_repository_fake.dart';
import 'package:crowdradar/app/fakes/moderacion_repository_fake.dart';
import 'package:crowdradar/app/fakes/perfil_repository_fake.dart';
import 'package:crowdradar/app/fakes/reporte_repository_fake.dart';
import 'package:crowdradar/app/fakes/validacion_repository_fake.dart';
import 'package:crowdradar/core/config/entorno.dart';
import 'package:crowdradar/core/location/geolocator_ubicacion_service.dart';
import 'package:crowdradar/core/map/tipos_mapa.dart';
import 'package:crowdradar/core/network/api_client.dart';
import 'package:crowdradar/core/session/session_service.dart';
import 'package:crowdradar/features/auth/data/auth_repository_http.dart';
import 'package:crowdradar/features/lugares/data/lugar_repository_http.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/ubicacion_fake.dart';

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
    expect(d.exploracionRepository, isA<ExploracionRepositoryFake>());
    expect(d.moderacionRepository, isA<ModeracionRepositoryFake>());
  });

  test('S6.1 usarFakes=false keeps the http implementations', () {
    final d = Dependencias.crear(const Entorno(), SessionService.instance);

    expect(d.authRepository, isA<AuthRepositoryHttp>());
    expect(d.lugarRepository, isA<LugarRepositoryHttp>());
  });

  test('CRO-60 the injected factory builds every repository', () {
    final d = Dependencias.crear(
      const Entorno(),
      SessionService.instance,
      repositorios: const FabricaRepositoriosFake(),
    );

    expect(d.authRepository, isA<AuthRepositoryFake>());
    expect(d.perfilRepository, isA<PerfilRepositoryFake>());
    expect(d.lugarRepository, isA<LugarRepositoryFake>());
    expect(d.reporteRepository, isA<ReporteRepositoryFake>());
    expect(d.analiticaRepository, isA<AnaliticaRepositoryFake>());
    expect(d.validacionRepository, isA<ValidacionRepositoryFake>());
    expect(d.favoritoRepository, isA<FavoritoRepositoryFake>());
    expect(d.alertaRepository, isA<AlertaRepositoryFake>());
    expect(d.exploracionRepository, isA<ExploracionRepositoryFake>());
    expect(d.moderacionRepository, isA<ModeracionRepositoryFake>());
  });

  test('CRO-60 the factory receives the app ApiClient and session', () {
    final espia = _FabricaEspia();
    final d = Dependencias.crear(
      const Entorno(),
      SessionService.instance,
      repositorios: espia,
    );

    expect(espia.api, same(d.apiClient));
    expect(espia.sesion, same(SessionService.instance));
  });

  test('CRO-65 the device location comes from geolocator by default', () {
    final d = Dependencias.crear(const Entorno(), SessionService.instance);

    expect(d.ubicacionService, isA<GeolocatorUbicacionService>());
  });

  test('CRO-65 the location service can be overridden (tests)', () {
    final propio = UbicacionServiceFake();
    final d = Dependencias.crear(
      const Entorno(usarFakes: true),
      SessionService.instance,
      ubicacionService: propio,
    );

    expect(d.ubicacionService, same(propio));
  });

  test(
    'CRO-65 the reference point joins that service and the map centre',
    () async {
      final ubicacion = UbicacionServiceFake();
      final d = Dependencias.crear(
        const Entorno(usarFakes: true),
        SessionService.instance,
        ubicacionService: ubicacion,
      );
      d.centroMapa.actualizar(
        const LimitesMapa(norte: -12, sur: -13, este: -76, oeste: -77),
      );

      expect(
        (await d.puntoReferencia.actualizar()).punto,
        const PuntoGeografico(-12.5, -76.5),
      );
      ubicacion.punto = miraflores;
      expect((await d.puntoReferencia.actualizar()).punto, miraflores);
    },
  );

  test('R1-101 fakes in a release build are refused', () {
    expect(
      () => Dependencias.crear(
        const Entorno(usarFakes: true),
        SessionService.instance,
        esRelease: true,
      ),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('USAR_FAKES'),
        ),
      ),
    );
  });

  test(
    'R1-101 release without fakes and non-release with fakes still work',
    () {
      expect(
        Dependencias.crear(
          const Entorno(),
          SessionService.instance,
          esRelease: true,
        ).authRepository,
        isA<AuthRepositoryHttp>(),
      );
      expect(
        Dependencias.crear(
          const Entorno(usarFakes: true),
          SessionService.instance,
          esRelease: false,
        ).authRepository,
        isA<AuthRepositoryFake>(),
      );
    },
  );
}

/// Records what the composition root hands to the factory.
class _FabricaEspia implements FabricaRepositorios {
  ApiClient? api;
  SessionService? sesion;

  @override
  Repositorios crear(ApiClient api, SessionService sesion) {
    this.api = api;
    this.sesion = sesion;
    return const FabricaRepositoriosHttp().crear(api, sesion);
  }
}
