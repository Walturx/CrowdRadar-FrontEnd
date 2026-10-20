// S6.1/S9.2 support: Dependencias wires every repository to its http implementation.
import 'package:crowdradar/app/dependencias.dart';
import 'package:crowdradar/core/config/entorno.dart';
import 'package:crowdradar/core/session/session_service.dart';
import 'package:crowdradar/features/alertas/data/alerta_repository_http.dart';
import 'package:crowdradar/features/analitica/data/analitica_repository_http.dart';
import 'package:crowdradar/features/exploracion/data/exploracion_repository_http.dart';
import 'package:crowdradar/features/favoritos/data/favorito_repository_http.dart';
import 'package:crowdradar/features/lugares/data/lugar_repository_http.dart';
import 'package:crowdradar/features/moderacion/data/moderacion_repository_http.dart';
import 'package:crowdradar/features/reportes/data/reporte_repository_http.dart';
import 'package:crowdradar/features/validacion/data/validacion_repository_http.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Dependencias.crear without fakes', () {
    test('resolves every repository to its http implementation', () {
      final d = Dependencias.crear(const Entorno(), SessionService.instance);

      expect(d.lugarRepository, isA<LugarRepositoryHttp>());
      expect(d.reporteRepository, isA<ReporteRepositoryHttp>());
      expect(d.analiticaRepository, isA<AnaliticaRepositoryHttp>());
      expect(d.validacionRepository, isA<ValidacionRepositoryHttp>());
      expect(d.favoritoRepository, isA<FavoritoRepositoryHttp>());
      expect(d.alertaRepository, isA<AlertaRepositoryHttp>());
      expect(d.exploracionRepository, isA<ExploracionRepositoryHttp>());
      expect(d.moderacionRepository, isA<ModeracionRepositoryHttp>());
    });
  });
}
