import 'package:crowdradar/features/perfil/cambiar_password/requisitos_password.dart';
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

  test('a multibyte password over 72 bytes fails the maximum', () {
    final p = 'Aa1${'ñ' * 35}'; // 38 characters, 73 bytes in UTF-8
    expect(p.length, lessThanOrEqualTo(64));
    expect(requisitosIncumplidos(p), [RequisitoPassword.maximo]);
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
