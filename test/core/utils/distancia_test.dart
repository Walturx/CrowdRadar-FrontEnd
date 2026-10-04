import 'package:crowdradar/core/map/tipos_mapa.dart';
import 'package:crowdradar/core/utils/distancia.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('distanciaMetros', () {
    test('is zero for the same point', () {
      const p = PuntoGeografico(-12.1219, -77.0297);

      expect(distanciaMetros(p, p), 0);
    });

    test('one degree of latitude is about 111 km', () {
      expect(
        distanciaMetros(
          const PuntoGeografico(0, 0),
          const PuntoGeografico(1, 0),
        ),
        closeTo(111195, 150),
      );
    });

    test('a short hop in Miraflores is about 315 m and is symmetric', () {
      const a = PuntoGeografico(-12.1219, -77.0297);
      const b = PuntoGeografico(-12.1219, -77.0268);

      expect(distanciaMetros(a, b), closeTo(315, 3));
      expect(distanciaMetros(b, a), closeTo(distanciaMetros(a, b), 1e-6));
    });
  });

  group('formatoDistancia', () {
    test('under a kilometre shows rounded metres', () {
      expect(formatoDistancia(316.4), '316 m');
      expect(formatoDistancia(0), '0 m');
    });

    test('a kilometre or more shows one decimal in km', () {
      expect(formatoDistancia(2600), '2.6 km');
      expect(formatoDistancia(1000), '1.0 km');
    });
  });
}
