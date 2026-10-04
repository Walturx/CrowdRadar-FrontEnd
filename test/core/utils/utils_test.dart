import 'package:crowdradar/core/utils/formato_fecha.dart';
import 'package:crowdradar/core/utils/validadores.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validadores', () {
    test('requerido rejects null, empty and blank', () {
      expect(Validadores.requerido(null), 'Este campo es obligatorio');
      expect(Validadores.requerido(''), 'Este campo es obligatorio');
      expect(Validadores.requerido('   '), 'Este campo es obligatorio');
      expect(Validadores.requerido('Ana'), isNull);
    });

    test('nombreApellido requires at least 2 characters', () {
      expect(Validadores.nombreApellido(null), 'Este campo es obligatorio');
      expect(Validadores.nombreApellido(' a '), 'Mínimo 2 caracteres');
      expect(Validadores.nombreApellido('Al'), isNull);
    });
  });

  group('haceCuanto', () {
    final ahora = DateTime.utc(2026, 10, 5, 12);

    test('under a minute is "ahora"', () {
      expect(
        haceCuanto(ahora.subtract(const Duration(seconds: 20)), ahora: ahora),
        'ahora',
      );
    });

    test('minutes, hours and days', () {
      expect(
        haceCuanto(ahora.subtract(const Duration(minutes: 5)), ahora: ahora),
        'hace 5 min',
      );
      expect(
        haceCuanto(ahora.subtract(const Duration(hours: 3)), ahora: ahora),
        'hace 3 h',
      );
      expect(
        haceCuanto(ahora.subtract(const Duration(days: 2)), ahora: ahora),
        'hace 2 d',
      );
    });

    test('a future date is treated as "ahora"', () {
      expect(
        haceCuanto(ahora.add(const Duration(minutes: 5)), ahora: ahora),
        'ahora',
      );
    });
  });
}
