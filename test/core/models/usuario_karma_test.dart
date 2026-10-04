import 'package:crowdradar/core/models/usuario.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('puntosKarma is read from the profile and survives copyWith', () {
    final u = Usuario.fromJson({'id': 1, 'puntosKarma': 40});

    expect(u.puntosKarma, 40);
    expect(u.copyWith(nombre: 'Ana').puntosKarma, 40);
    expect(u.copyWith(puntosKarma: 50).puntosKarma, 50);
    expect(Usuario.fromJson({'id': 1}).puntosKarma, isNull);
  });

  test('karma takes part in equality', () {
    expect(
      const Usuario(id: 1, puntosKarma: 1),
      isNot(const Usuario(id: 1, puntosKarma: 2)),
    );
  });
}
