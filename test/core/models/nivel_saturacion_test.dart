import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NivelSaturacion.desdePromedio', () {
    test('uses the named cutoffs', () {
      expect(NivelSaturacion.corteModerado, 1.67);
      expect(NivelSaturacion.corteSaturado, 2.34);
    });

    test('below 1.67 is tranquilo, 1.67 up to 2.34 is moderado', () {
      expect(NivelSaturacion.desdePromedio(1), NivelSaturacion.tranquilo);
      expect(NivelSaturacion.desdePromedio(1.66), NivelSaturacion.tranquilo);
      expect(NivelSaturacion.desdePromedio(1.67), NivelSaturacion.moderado);
      expect(NivelSaturacion.desdePromedio(2.33), NivelSaturacion.moderado);
    });

    test('2.34 and above is saturado', () {
      expect(NivelSaturacion.desdePromedio(2.34), NivelSaturacion.saturado);
      expect(NivelSaturacion.desdePromedio(3), NivelSaturacion.saturado);
    });

    test('out-of-range values still map to the nearest end', () {
      expect(NivelSaturacion.desdePromedio(-1), NivelSaturacion.tranquilo);
      expect(NivelSaturacion.desdePromedio(9), NivelSaturacion.saturado);
    });
  });
}
