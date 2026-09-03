import 'package:crowdradar/core/session/jwt_util.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/jwt_falso.dart';

void main() {
  final ahora = DateTime.utc(2026, 10, 5, 12);

  test('future exp is not expired', () {
    final token = jwtFalso(exp: ahora.add(const Duration(hours: 1)));

    expect(JwtUtil.estaExpirado(token, ahora: ahora), isFalse);
  });

  test('past exp is expired', () {
    final token = jwtFalso(exp: ahora.subtract(const Duration(seconds: 1)));

    expect(JwtUtil.estaExpirado(token, ahora: ahora), isTrue);
  });

  test('exp equal to now counts as expired', () {
    expect(JwtUtil.estaExpirado(jwtFalso(exp: ahora), ahora: ahora), isTrue);
  });

  test('malformed tokens are treated as expired', () {
    expect(JwtUtil.estaExpirado('basura', ahora: ahora), isTrue);
    expect(JwtUtil.estaExpirado('a.%%%.c', ahora: ahora), isTrue);
    expect(JwtUtil.estaExpirado('', ahora: ahora), isTrue);
  });

  test('expiracion returns the exp instant', () {
    final exp = ahora.add(const Duration(minutes: 5));

    expect(JwtUtil.expiracion(jwtFalso(exp: exp)), exp);
  });
}
