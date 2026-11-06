import 'package:crowdradar/core/models/enum_api.dart';
import 'package:crowdradar/core/models/tier_usuario.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // (wire value, tier, display name, badge) as CRO-72 / CRO-74 define them.
  const casos = [
    (
      'CROWD_BABY',
      TierUsuario.crowdBaby,
      'Crowd Baby',
      'assets/images/tier_crowd_baby.png',
    ),
    (
      'CROWD_EXPLORER',
      TierUsuario.crowdExplorer,
      'Crowd Explorer',
      'assets/images/tier_crowd_explorer.png',
    ),
    (
      'CROWD_COLLABORATOR',
      TierUsuario.crowdCollaborator,
      'Crowd Collaborator',
      'assets/images/tier_crowd_collaborator.png',
    ),
    (
      'CROWD_ROYALTY',
      TierUsuario.crowdRoyalty,
      'Crowd Royalty',
      'assets/images/tier_crowd_royalty.png',
    ),
  ];

  for (final (wire, tier, nombre, insignia) in casos) {
    test('$wire parses to $nombre with its badge', () {
      final leido = TierUsuario.desdeApi(wire);

      expect(leido, tier);
      expect(leido.nombre, nombre);
      expect(leido.insignia, insignia);
      expect(valorApi(leido), wire);
    });
  }

  test('there are exactly the four tiers of CRO-72', () {
    expect(TierUsuario.values, [for (final c in casos) c.$2]);
  });

  for (final crudo in [null, '', 'KARMA', 'crowd_baby', 3]) {
    test('an unknown or missing value ($crudo) falls back to Crowd Baby', () {
      expect(TierUsuario.desdeApi(crudo), TierUsuario.crowdBaby);
    });
  }
}
