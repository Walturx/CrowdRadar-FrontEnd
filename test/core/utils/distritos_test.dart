import 'package:crowdradar/core/utils/distritos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lists the 43 districts of Lima and the 7 of Callao, once each', () {
    expect(distritos, hasLength(50));
    expect(distritos.toSet(), hasLength(50));
    expect(
      distritos,
      containsAll(<String>[
        'Lima',
        'Miraflores',
        'Callao',
        'Ventanilla',
        'Mi Perú',
      ]),
    );
  });

  test('keeps the alphabetical order the backend uses', () {
    expect(distritos.first, 'Ancón');
    expect(distritos.last, 'Villa María del Triunfo');
    expect(
      distritos.indexOf('Mi Perú'),
      lessThan(distritos.indexOf('Miraflores')),
    );
  });
}
