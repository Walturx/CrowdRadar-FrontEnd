import 'package:crowdradar/core/map/centro_compartido.dart';
import 'package:crowdradar/core/map/tipos_mapa.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults to Lima and follows the last bounds', () {
    final c = CentroMapaCompartido();
    expect(c.actual, CentroMapaCompartido.lima);

    c.actualizar(
      const LimitesMapa(norte: -12, sur: -13, este: -76, oeste: -77),
    );

    expect(c.actual, const PuntoGeografico(-12.5, -76.5));
  });
}
