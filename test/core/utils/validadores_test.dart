import 'package:crowdradar/core/utils/validadores.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('telefono (9 digits starting with 9, or empty)', () {
    test('accepts 9 digits starting with 9, or empty', () {
      expect(Validadores.telefono('987654321'), isNull);
      expect(Validadores.telefono(''), isNull);
      expect(Validadores.telefono(null), isNull);
    });

    test('rejects other lengths and prefixes', () {
      const mensaje = 'Ingresá un celular de 9 dígitos que empiece en 9';
      expect(Validadores.telefono('887654321'), mensaje);
      expect(Validadores.telefono('98765432'), mensaje);
      expect(Validadores.telefono('9876543210'), mensaje);
      expect(Validadores.telefono('98765432a'), mensaje);
    });
  });

  group('distrito (required, one of the 50 of Lima and Callao)', () {
    test('rejects no selection and values outside the list', () {
      const mensaje = 'Selecciona tu distrito';
      expect(Validadores.distrito(null), mensaje);
      expect(Validadores.distrito(''), mensaje);
      expect(Validadores.distrito('Narnia'), mensaje);
      expect(Validadores.distrito('miraflores'), mensaje);
    });

    test('accepts a district of Lima and one of Callao', () {
      expect(Validadores.distrito('Ate'), isNull);
      expect(Validadores.distrito('Ventanilla'), isNull);
    });
  });

  group('correo', () {
    test('accepts a plain address and trims it', () {
      expect(Validadores.correo('ana@test.com'), isNull);
      expect(Validadores.correo(' ana@test.com '), isNull);
    });

    test('empty is required, malformed is invalid', () {
      expect(Validadores.correo(''), Validadores.mensajeObligatorio);
      expect(Validadores.correo(null), Validadores.mensajeObligatorio);
      expect(Validadores.correo('ana'), 'Correo inválido');
      expect(Validadores.correo('ana@test'), 'Correo inválido');
      expect(Validadores.correo('a b@test.com'), 'Correo inválido');
    });

    test('esCorreo is the shared format check', () {
      expect(Validadores.esCorreo('ana@test.com'), isTrue);
      expect(Validadores.esCorreo('ana@'), isFalse);
    });
  });
}
