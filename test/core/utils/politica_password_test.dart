import 'package:crowdradar/core/utils/politica_password.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a strong password meets every requirement', () {
    expect(requisitosIncumplidos('Secreta1'), isEmpty);
  });

  test('7 characters fail only the minimum, 8 pass (BVA)', () {
    expect(requisitosIncumplidos('Secret1'), [RequisitoPassword.minimo]);
    expect(requisitosIncumplidos('Secreta1'), isEmpty);
  });

  test('64 characters pass, 65 fail only the maximum (BVA)', () {
    final base = 'Aa1${'x' * 61}';
    expect(base.length, 64);
    expect(requisitosIncumplidos(base), isEmpty);
    expect(requisitosIncumplidos('${base}x'), [RequisitoPassword.maximo]);
  });

  test('a multibyte password over 72 bytes fails the byte limit only', () {
    final p = 'Aa1${'ñ' * 35}'; // 38 characters, 73 bytes in UTF-8
    expect(p.length, lessThanOrEqualTo(64));
    expect(requisitosIncumplidos(p), [RequisitoPassword.maximoBytes]);
  });

  test('72 bytes pass, 73 fail (BVA on bytes)', () {
    expect(requisitosIncumplidos('Aa1${'ñ' * 34}'), isEmpty); // 71 bytes
    expect(requisitosIncumplidos('Aa1${'ñ' * 34}a'), isEmpty); // 72 bytes
    expect(requisitosIncumplidos('Aa1${'ñ' * 34}ñ'), [
      RequisitoPassword.maximoBytes,
    ]);
  });

  test('emoji count as one character: length is in code points', () {
    // 19 code points (39 UTF-16 units), 67 bytes: valid.
    expect(requisitosIncumplidos('Aa1${'😀' * 4 * 4}'), isEmpty);
    // 7 code points (11 UTF-16 units): too short.
    expect(requisitosIncumplidos('Aa1${'😀' * 4}'), [RequisitoPassword.minimo]);
    // 21 code points but 75 bytes: only the byte limit fails.
    expect(requisitosIncumplidos('Aa1${'😀' * 18}'), [
      RequisitoPassword.maximoBytes,
    ]);
  });

  test('the byte limit has its own text', () {
    expect(
      RequisitoPassword.maximoBytes.texto,
      isNot(RequisitoPassword.maximo.texto),
    );
    expect(RequisitoPassword.maximoBytes.texto, contains('72'));
  });

  test('validarPassword: required, then the first unmet requirement', () {
    expect(validarPassword(''), 'Este campo es obligatorio');
    expect(validarPassword(null), 'Este campo es obligatorio');
    expect(validarPassword('Secret1'), RequisitoPassword.minimo.texto);
    expect(validarPassword('secretaaa'), RequisitoPassword.mayuscula.texto);
    expect(validarPassword('Secreta1'), isNull);
  });

  test('no uppercase and no digit are reported separately', () {
    expect(requisitosIncumplidos('secretaaa'), [
      RequisitoPassword.mayuscula,
      RequisitoPassword.numero,
    ]);
  });

  test('an empty password reports every requirement but the maximum', () {
    expect(requisitosIncumplidos(''), [
      RequisitoPassword.minimo,
      RequisitoPassword.mayuscula,
      RequisitoPassword.numero,
    ]);
  });

  test('each requirement has user-facing text', () {
    expect(RequisitoPassword.minimo.texto, 'Al menos 8 caracteres');
    expect(RequisitoPassword.maximo.texto, 'Máximo 64 caracteres');
    expect(RequisitoPassword.mayuscula.texto, 'Al menos una mayúscula');
    expect(RequisitoPassword.numero.texto, 'Al menos un número');
  });
}
