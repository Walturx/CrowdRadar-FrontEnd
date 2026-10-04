import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/utils/mensaje_error.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ApiException keeps its message, code and offline flag', () {
    const e = ApiException(status: 409, message: 'Duplicado', code: 'DUP');
    expect(mensajeDeError(e), 'Duplicado');
    expect(codigoDeError(e), 'DUP');
    expect(esErrorSinConexion(e), isFalse);
    expect(esErrorSinConexion(const ApiException.sinConexion()), isTrue);
  });

  test('any other error maps to the generic message', () {
    expect(mensajeDeError(StateError('x')), mensajeGenerico);
    expect(codigoDeError(StateError('x')), isNull);
    expect(esErrorSinConexion(StateError('x')), isFalse);
  });

  test('field errors come from ApiException only', () {
    const e = ApiException(
      status: 400,
      message: 'm',
      errors: [ErrorCampo(campo: 'a', mensaje: 'b')],
    );
    expect(erroresPorCampo(e), {'a': 'b'});
    expect(erroresPorCampo(StateError('x')), isEmpty);
  });
}
