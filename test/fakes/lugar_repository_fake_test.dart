import 'package:crowdradar/app/fakes/comportamiento_fake.dart';
import 'package:crowdradar/app/fakes/lugar_repository_fake.dart';
import 'package:crowdradar/core/map/tipos_mapa.dart';
import 'package:crowdradar/core/models/categoria_lugar.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/features/lugares/data/lugar_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _lima = LimitesMapa(norte: -11.85, sur: -12.25, este: -76.85, oeste: -77.20);
const _miraflores = LimitesMapa(norte: -12.11, sur: -12.13, este: -77.02, oeste: -77.04);
final _ahora = DateTime.utc(2026, 10, 4, 15);

Matcher _falla(int status, String code) => throwsA(
  isA<ApiException>()
      .having((e) => e.status, 'status', status)
      .having((e) => e.code, 'code', code),
);

void main() {
  final LugarRepository repo = LugarRepositoryFake(reloj: () => _ahora);

  group('seed', () {
    test('Lima bbox returns the 45 places with unique ids', () async {
      final res = await repo.buscar(bbox: _lima);

      expect(res.items, hasLength(45));
      expect(res.items.map((l) => l.id).toSet(), hasLength(45));
    });

    test('has at least 5 places in each of the 6 categories', () async {
      final res = await repo.buscar(bbox: _lima);

      for (final c in CategoriaLugar.values) {
        expect(
          res.items.where((l) => l.categoria == c).length,
          greaterThanOrEqualTo(5),
          reason: '$c',
        );
      }
    });

    test('every saturation level is represented', () async {
      final res = await repo.buscar(bbox: _lima);

      for (final n in NivelSaturacion.values) {
        expect(res.items.any((l) => l.saturacion == n), isTrue, reason: '$n');
      }
    });

    test('items come ordered by nombre', () async {
      final res = await repo.buscar(bbox: _lima);
      final nombres = res.items.map((l) => l.nombre).toList();

      expect(nombres, [...nombres]..sort());
    });
  });

  group('filters', () {
    test('bbox keeps only the places inside it', () async {
      final res = await repo.buscar(bbox: _miraflores);

      expect(res.items, isNotEmpty);
      expect(res.items.length, lessThan(45));
      for (final l in res.items) {
        expect(l.latitud, inInclusiveRange(_miraflores.sur, _miraflores.norte));
        expect(l.longitud, inInclusiveRange(_miraflores.oeste, _miraflores.este));
      }
      expect(res.items.map((l) => l.nombre), contains('Parque Kennedy'));
      expect(res.items.map((l) => l.nombre), isNot(contains('Mercado de Surquillo')));
    });

    test('q ignores case and accents', () async {
      final base = await repo.buscar(q: 'parque');
      final mayus = await repo.buscar(q: 'PARQUE');
      final tilde = await repo.buscar(q: 'Párque');

      expect(base.items.length, greaterThan(1));
      expect(mayus.items, base.items);
      expect(tilde.items, base.items);
      expect(base.items.every((l) => l.nombre.toLowerCase().contains('parque')), isTrue);
    });

    test('q matches an accented name with an unaccented query and vice versa', () async {
      final sin = await repo.buscar(q: 'exposicion');
      final con = await repo.buscar(q: 'exposición');

      expect(sin.items.single.nombre, 'Parque de la Exposición');
      expect(con.items, sin.items);
    });

    test('categoria narrows the result', () async {
      final res = await repo.buscar(bbox: _lima, categoria: CategoriaLugar.playa);

      expect(res.items, isNotEmpty);
      expect(res.items.every((l) => l.categoria == CategoriaLugar.playa), isTrue);
    });

    test('nivel narrows the result', () async {
      final res = await repo.buscar(bbox: _lima, nivel: NivelSaturacion.sinInformacion);

      expect(res.items, isNotEmpty);
      expect(res.items.every((l) => l.saturacion == NivelSaturacion.sinInformacion), isTrue);
    });

    test('filters combine with AND', () async {
      final soloQ = await repo.buscar(q: 'plaza');
      final res = await repo.buscar(
        q: 'plaza',
        bbox: _lima,
        categoria: CategoriaLugar.plaza,
        nivel: NivelSaturacion.tranquilo,
      );

      expect(res.items, isNotEmpty);
      expect(res.items.length, lessThan(soloQ.items.length));
      expect(
        res.items.every((l) =>
            l.nombre.toLowerCase().contains('plaza') &&
            l.categoria == CategoriaLugar.plaza &&
            l.saturacion == NivelSaturacion.tranquilo),
        isTrue,
      );
    });

    test('limite truncates after ordering', () async {
      final todos = await repo.buscar(bbox: _lima);
      final res = await repo.buscar(bbox: _lima, limite: 5);

      expect(res.items, todos.items.take(5).toList());
    });
  });

  group('empty and invalid', () {
    test('no match with q explains it with the query', () async {
      final res = await repo.buscar(q: 'Zoológico');

      expect(res.estaVacia, isTrue);
      expect(res.mensaje, 'No encontramos lugares para “Zoológico”. Prueba con otro nombre.');
    });

    test('no match without q explains the zone is empty', () async {
      final res = await repo.buscar(
        bbox: const LimitesMapa(norte: -13, sur: -14, este: -78, oeste: -79),
      );

      expect(res.estaVacia, isTrue);
      expect(res.mensaje, 'No hay lugares en esta zona.');
    });

    test('a non-empty result carries no message', () async {
      expect((await repo.buscar(bbox: _lima)).mensaje, isEmpty);
    });

    test('q shorter than 2 chars is a 400', () async {
      await expectLater(repo.buscar(q: 'a'), _falla(400, 'VALIDACION_FALLIDA'));
      await expectLater(repo.buscar(q: ' a '), _falla(400, 'VALIDACION_FALLIDA'));
    });

    test('neither q nor bbox is a 400', () async {
      await expectLater(repo.buscar(), _falla(400, 'VALIDACION_FALLIDA'));
    });

    test('a configured failure is thrown', () async {
      final caido = LugarRepositoryFake(
        comportamiento: const ComportamientoFake(fallo: ApiException.sinConexion()),
      );

      await expectLater(
        caido.buscar(bbox: _lima),
        throwsA(isA<ApiException>().having((e) => e.esSinConexion, 'offline', true)),
      );
    });
  });

  group('obtener', () {
    test('returns name, address and category of the place', () async {
      final d = await repo.obtener(1);

      expect(d.nombre, 'Parque Kennedy');
      expect(d.direccion, 'Av. Larco 345, Miraflores');
      expect(d.categoria, CategoriaLugar.parque);
    });

    test('a fresh level carries its update time and report count', () async {
      final d = await repo.obtener(1);

      expect(d.saturacion.nivel, NivelSaturacion.tranquilo);
      expect(d.saturacion.actualizadoEn, isNotNull);
      expect(_ahora.difference(d.saturacion.actualizadoEn!).inMinutes, inInclusiveRange(1, 59));
      expect(d.saturacion.reportesRecientes, greaterThan(0));
    });

    test('SIN_INFORMACION has no update time and explains why', () async {
      final d = await repo.obtener(8);

      expect(d.saturacion.nivel, NivelSaturacion.sinInformacion);
      expect(d.saturacion.actualizadoEn, isNull);
      expect(d.saturacion.reportesRecientes, 0);
      expect(
        d.saturacion.mensaje,
        'Aún no hay reportes suficientes para determinar la saturación de este lugar.',
      );
    });

    test('is deterministic across calls', () async {
      expect(await repo.obtener(2), await repo.obtener(2));
    });

    test('an unknown id is a 404 LUGAR_NO_ENCONTRADO', () async {
      await expectLater(repo.obtener(9999), _falla(404, 'LUGAR_NO_ENCONTRADO'));
    });
  });
}
