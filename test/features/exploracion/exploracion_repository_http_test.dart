import 'package:crowdradar/core/models/categoria_lugar.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/session/session_service.dart';
import 'package:crowdradar/features/exploracion/data/exploracion_repository_http.dart';
import 'package:crowdradar/features/exploracion/data/filtro_exploracion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../fakes/http_falso.dart';

Map<String, dynamic> _lugar(int id) => {
  'id': id,
  'nombre': 'Parque $id',
  'categoria': 'PARQUE',
  'latitud': -12.12,
  'longitud': -77.03,
  'saturacion': 'TRANQUILO',
  'distanciaMetros': 315.5,
};

void main() {
  late SessionService sesion;
  http.Request? visto;

  ExploracionRepositoryHttp repo(int status, Object? body) {
    visto = null;
    return ExploracionRepositoryHttp(
      apiClientPrueba((r) async {
        visto = r;
        return respuestaJson(status, body);
      }, sesion),
    );
  }

  setUp(() => sesion = SessionService.instance..reiniciar());
  tearDown(() => sesion.reiniciar());

  group('explorar', () {
    test('serializes every filter with the wire enum values', () async {
      final r = repo(200, {
        'message': '',
        'data': {
          'items': [_lugar(1), _lugar(2)],
        },
      });

      final res = await r.explorar(
        const FiltroExploracion(
          categoria: CategoriaLugar.centroComercial,
          saturacion: NivelSaturacion.sinInformacion,
          lat: -12.1,
          lng: -77.0,
          radioKm: 3,
        ),
      );

      expect(visto!.url.path, '/api/lugares/explorar');
      expect(visto!.url.queryParameters, {
        'categoria': 'CENTRO_COMERCIAL',
        'saturacion': 'SIN_INFORMACION',
        'lat': '-12.1',
        'lng': '-77.0',
        'radioKm': '3.0',
      });
      expect(res.items.map((l) => l.id), [1, 2]);
      expect(res.items.first.distanciaMetros, 315.5);
    });

    test('no filters sends no query; empty result keeps the message', () async {
      final r = repo(200, {
        'message': 'No hay lugares cercanos disponibles para esa categoría.',
        'data': {'items': []},
      });

      final res = await r.explorar(const FiltroExploracion());

      expect(visto!.url.queryParameters, isEmpty);
      expect(res.estaVacia, isTrue);
      expect(
        res.mensaje,
        'No hay lugares cercanos disponibles para esa categoría.',
      );
    });

    test('400 and offline surface as ApiException', () async {
      await expectLater(
        repo(400, {
          'code': 'VALIDACION_FALLIDA',
          'message': 'x',
        }).explorar(const FiltroExploracion(lat: -12)),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 400)),
      );
      final sinRed = ExploracionRepositoryHttp(
        apiClientPrueba((_) async => throw http.ClientException('x'), sesion),
      );
      await expectLater(
        sinRed.explorar(const FiltroExploracion()),
        throwsA(
          isA<ApiException>().having((e) => e.esSinConexion, 'off', true),
        ),
      );
    });
  });

  group('listarCategorias', () {
    test('GETs /api/lugares/categorias and maps the items', () async {
      final r = repo(200, {
        'message': '',
        'data': {
          'items': [
            {'categoria': 'PARQUE', 'etiqueta': 'Parques', 'total': 12},
            {'categoria': 'PLAYA', 'etiqueta': 'Playas', 'total': 0},
          ],
        },
      });

      final res = await r.listarCategorias();

      expect(visto!.url.path, '/api/lugares/categorias');
      expect(res.map((c) => c.categoria), [
        CategoriaLugar.parque,
        CategoriaLugar.playa,
      ]);
      expect(res.map((c) => c.etiqueta), ['Parques', 'Playas']);
      expect(res.map((c) => c.total), [12, 0]);
    });
  });
}
