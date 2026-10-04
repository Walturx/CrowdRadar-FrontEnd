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

  group('distrito (at least 2 characters)', () {
    test('rejects empty and one character', () {
      expect(Validadores.distrito(''), 'Ingresá tu distrito');
      expect(Validadores.distrito(' a '), 'Ingresá tu distrito');
      expect(Validadores.distrito(null), 'Ingresá tu distrito');
    });

    test('accepts two characters', () {
      expect(Validadores.distrito('Ate'), isNull);
      expect(Validadores.distrito(' Ate '), isNull);
    });
  });
}
