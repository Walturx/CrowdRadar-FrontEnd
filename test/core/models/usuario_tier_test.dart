import 'package:crowdradar/core/models/tier_usuario.dart';
import 'package:crowdradar/core/models/usuario.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('puntos and tier are read from the user object (C1)', () {
    final u = Usuario.fromJson({
      'id': 1,
      'puntos': 120,
      'tier': 'CROWD_EXPLORER',
    });

    expect(u.puntos, 120);
    expect(u.tier, TierUsuario.crowdExplorer);
  });

  test('puntos and tier survive copyWith', () {
    final u = Usuario.fromJson({
      'id': 1,
      'puntos': 160,
      'tier': 'CROWD_COLLABORATOR',
    });

    expect(u.copyWith(nombre: 'Ana').puntos, 160);
    expect(u.copyWith(nombre: 'Ana').tier, TierUsuario.crowdCollaborator);
    expect(u.copyWith(puntos: 300).puntos, 300);
    expect(
      u.copyWith(tier: TierUsuario.crowdRoyalty).tier,
      TierUsuario.crowdRoyalty,
    );
  });

  test('a user object without them is 0 points and Crowd Baby', () {
    final u = Usuario.fromJson({'id': 1});

    expect(u.puntos, 0);
    expect(u.tier, TierUsuario.crowdBaby);
  });

  test('the legacy puntosKarma field is ignored', () {
    final u = Usuario.fromJson({'id': 1, 'puntosKarma': 999});

    expect(u.puntos, 0);
    expect(u.toJson().containsKey('puntosKarma'), isFalse);
  });

  test('toJson writes the wire values, so fromJson round-trips', () {
    const u = Usuario(id: 1, puntos: 310, tier: TierUsuario.crowdRoyalty);

    expect(u.toJson()['puntos'], 310);
    expect(u.toJson()['tier'], 'CROWD_ROYALTY');
    expect(Usuario.fromJson(u.toJson()), u);
  });

  test('puntos and tier take part in equality', () {
    expect(
      const Usuario(id: 1, puntos: 1),
      isNot(const Usuario(id: 1, puntos: 2)),
    );
    expect(
      const Usuario(id: 1, tier: TierUsuario.crowdBaby),
      isNot(const Usuario(id: 1, tier: TierUsuario.crowdExplorer)),
    );
  });
}
