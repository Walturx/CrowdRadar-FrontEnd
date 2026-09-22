// S6.1/S9.2 support: every frozen repository has an ApiClient-backed stub that
// fails with 501 until its stream implements it, and Dependencias wires them.
import 'package:crowdradar/app/dependencias.dart';
import 'package:crowdradar/core/config/entorno.dart';
import 'package:crowdradar/core/models/moderacion.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/models/validacion.dart';
import 'package:crowdradar/core/network/api_client.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/session/session_service.dart';
import 'package:crowdradar/features/analitica/data/analitica_repository.dart';
import 'package:crowdradar/features/analitica/data/analitica_repository_http.dart';
import 'package:crowdradar/features/favoritos/data/favorito_repository.dart';
import 'package:crowdradar/features/favoritos/data/favorito_repository_http.dart';
import 'package:crowdradar/features/lugares/data/lugar_repository_http.dart';
import 'package:crowdradar/features/moderacion/data/moderacion_repository.dart';
import 'package:crowdradar/features/moderacion/data/moderacion_repository_http.dart';
import 'package:crowdradar/features/reportes/data/reporte_repository.dart';
import 'package:crowdradar/features/reportes/data/reporte_repository_http.dart';
import 'package:crowdradar/features/validacion/data/validacion_repository.dart';
import 'package:crowdradar/features/validacion/data/validacion_repository_http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../fakes/http_falso.dart';

Matcher get _noImplementado => throwsA(
  isA<ApiException>()
      .having((e) => e.status, 'status', 501)
      .having((e) => e.code, 'code', 'NO_IMPLEMENTADO'),
);

void main() {
  late ApiClient api;
  var peticiones = 0;

  setUp(() {
    peticiones = 0;
    api = apiClientPrueba((_) async {
      peticiones++;
      return http.Response('{}', 200);
    }, SessionService.instance..reiniciar());
  });

  tearDown(
    () => expect(peticiones, 0, reason: 'stubs must not hit the network'),
  );

  group('stubs fail with 501', () {
    test('ReporteRepository', () {
      final ReporteRepository r = ReporteRepositoryHttp(api);

      expect(() => r.reportar(1, NivelSaturacion.saturado), _noImplementado);
      expect(() => r.listarMios(), _noImplementado);
    });

    test('AnaliticaRepository', () {
      final AnaliticaRepository r = AnaliticaRepositoryHttp(api);

      expect(() => r.historial(1), _noImplementado);
      expect(() => r.mejorHorario(1), _noImplementado);
    });

    test('ValidacionRepository', () {
      final ValidacionRepository r = ValidacionRepositoryHttp(api);

      expect(() => r.pendientes(), _noImplementado);
      expect(
        () => r.validar(1, TipoAccionValidacion.confirmar),
        _noImplementado,
      );
      expect(() => r.denunciar(1, MotivoDenuncia.spam), _noImplementado);
    });

    test('FavoritoRepository', () {
      final FavoritoRepository r = FavoritoRepositoryHttp(api);

      expect(() => r.listar(), _noImplementado);
      expect(() => r.configurarAlertas(1, activadas: true), _noImplementado);
    });

    test('ModeracionRepository', () {
      final ModeracionRepository r = ModeracionRepositoryHttp(api);

      expect(() => r.reportesDenunciados(), _noImplementado);
      expect(() => r.resolver(1, DecisionModeracion.eliminar), _noImplementado);
      expect(
        () => r.suspender(1, dias: 3, motivo: 'Spam reiterado'),
        _noImplementado,
      );
    });
  });

  group('Dependencias.crear without fakes', () {
    test('resolves every repository to its http implementation', () {
      final d = Dependencias.crear(const Entorno(), SessionService.instance);

      expect(d.lugarRepository, isA<LugarRepositoryHttp>());
      expect(d.reporteRepository, isA<ReporteRepositoryHttp>());
      expect(d.analiticaRepository, isA<AnaliticaRepositoryHttp>());
      expect(d.validacionRepository, isA<ValidacionRepositoryHttp>());
      expect(d.favoritoRepository, isA<FavoritoRepositoryHttp>());
      expect(d.moderacionRepository, isA<ModeracionRepositoryHttp>());
    });
  });
}
