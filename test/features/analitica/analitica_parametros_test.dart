import 'package:crowdradar/features/analitica/analitica_parametros.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the comparison weeks are derived from the 28-day window', () {
    expect(AnaliticaParametros.diasVentanaComparacion, 28);
    expect(AnaliticaParametros.semanasComparacion, 4);
    expect(
      AnaliticaParametros.semanasComparacion * 7,
      AnaliticaParametros.diasVentanaComparacion,
    );
  });

  test('windows, limits and day groups are defined once', () {
    expect(AnaliticaParametros.diasHistorialCorto, 7);
    expect(AnaliticaParametros.topFranjas, 3);
    expect(AnaliticaParametros.horaApertura, 8);
    expect(AnaliticaParametros.horaCierre, 22);
    expect(AnaliticaParametros.maxDiasRango, 31);
    expect(AnaliticaParametros.laborables, 'LABORABLES');
    expect(AnaliticaParametros.finDeSemana, 'FIN_DE_SEMANA');
  });
}
