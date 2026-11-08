// CRO-60: the composition root builds its repositories through a
// FabricaRepositorios; the app ships the HTTP one and tests inject the fakes.
import 'package:crowdradar/app/dependencias.dart';
import 'package:crowdradar/app/fabrica_repositorios.dart';
import 'package:crowdradar/core/config/entorno.dart';
import 'package:crowdradar/core/location/geolocator_ubicacion_service.dart';
import 'package:crowdradar/core/map/tipos_mapa.dart';
import 'package:crowdradar/core/network/api_client.dart';
import 'package:crowdradar/core/push/receptor_push_nulo.dart';
import 'package:crowdradar/core/session/session_service.dart';
import 'package:crowdradar/features/alertas/data/alerta_repository_http.dart';
import 'package:crowdradar/features/analitica/data/analitica_repository_http.dart';
import 'package:crowdradar/features/auth/data/auth_repository_http.dart';
import 'package:crowdradar/features/exploracion/data/exploracion_repository_http.dart';
import 'package:crowdradar/features/favoritos/data/favorito_repository_http.dart';
import 'package:crowdradar/features/lugares/data/lugar_repository_http.dart';
import 'package:crowdradar/features/moderacion/data/moderacion_repository_http.dart';
import 'package:crowdradar/features/perfil/data/perfil_repository_http.dart';
import 'package:crowdradar/features/reportes/data/reporte_repository_http.dart';
import 'package:crowdradar/features/validacion/data/validacion_repository_http.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/alerta_repository_fake.dart';
import '../fakes/analitica_repository_fake.dart';
import '../fakes/auth_repository_fake.dart';
import '../fakes/exploracion_repository_fake.dart';
import '../fakes/fabrica_repositorios_fake.dart';
import '../fakes/favorito_repository_fake.dart';
import '../fakes/lugar_repository_fake.dart';
import '../fakes/moderacion_repository_fake.dart';
import '../fakes/perfil_repository_fake.dart';
import '../fakes/reporte_repository_fake.dart';
import '../fakes/validacion_repository_fake.dart';
import '../helpers/ubicacion_fake.dart';

void main() {
  tearDown(() => SessionService.instance.reiniciar());

  test('CRO-60 the app builds the HTTP repositories by default', () {
    final d = Dependencias.crear(const Entorno(), SessionService.instance);

    expect(d.authRepository, isA<AuthRepositoryHttp>());
    expect(d.perfilRepository, isA<PerfilRepositoryHttp>());
    expect(d.lugarRepository, isA<LugarRepositoryHttp>());
    expect(d.reporteRepository, isA<ReporteRepositoryHttp>());
    expect(d.analiticaRepository, isA<AnaliticaRepositoryHttp>());
    expect(d.validacionRepository, isA<ValidacionRepositoryHttp>());
    expect(d.favoritoRepository, isA<FavoritoRepositoryHttp>());
    expect(d.alertaRepository, isA<AlertaRepositoryHttp>());
    expect(d.exploracionRepository, isA<ExploracionRepositoryHttp>());
    expect(d.moderacionRepository, isA<ModeracionRepositoryHttp>());
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

  test('CRO-60 the push receiver is the no-op one by default', () {
    final conHttp = Dependencias.crear(
      const Entorno(),
      SessionService.instance,
    );
    final conFakes = Dependencias.crear(
      const Entorno(),
      SessionService.instance,
      repositorios: const FabricaRepositoriosFake(),
    );

    expect(conHttp.receptorPush, isA<ReceptorPushNulo>());
    expect(conFakes.receptorPush, isA<ReceptorPushNulo>());
  });

  test('CRO-65 the device location comes from geolocator by default', () {
    final d = Dependencias.crear(const Entorno(), SessionService.instance);

    expect(d.ubicacionService, isA<GeolocatorUbicacionService>());
  });

  test('CRO-65 the location service can be overridden (tests)', () {
    final propio = UbicacionServiceFake();
    final d = Dependencias.crear(
      const Entorno(),
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
        const Entorno(),
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
