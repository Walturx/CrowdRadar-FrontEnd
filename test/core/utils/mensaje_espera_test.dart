import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/utils/mensaje_espera.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rounds the wait up to whole minutes with singular and plural', () {
    expect(segundosPorMinuto, 60);
    expect(mensajeEspera(1), 'Demasiados intentos, probá en 1 minuto');
    expect(mensajeEspera(60), 'Demasiados intentos, probá en 1 minuto');
    expect(mensajeEspera(61), 'Demasiados intentos, probá en 2 minutos');
    expect(mensajeEspera(125), 'Demasiados intentos, probá en 3 minutos');
  });

  test('no wait information falls back to a generic text', () {
    expect(mensajeEspera(null), 'Demasiados intentos, probá más tarde');
    expect(mensajeEspera(0), 'Demasiados intentos, probá más tarde');
  });

  test('a rate limit is a 429 or one of its codes', () {
    expect(
      esLimiteDeIntentos(const ApiException(status: 429, message: 'x')),
      isTrue,
    );
    expect(
      esLimiteDeIntentos(
        const ApiException(
          status: 400,
          message: 'x',
          code: 'DEMASIADOS_INTENTOS',
        ),
      ),
      isTrue,
    );
    expect(
      esLimiteDeIntentos(const ApiException(status: 422, message: 'x')),
      isFalse,
    );
    expect(esLimiteDeIntentos(StateError('x')), isFalse);
  });
}
