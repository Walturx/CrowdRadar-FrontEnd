import 'enum_api.dart';

/// Informational tier the backend assigns from the user's points (CRO-72):
/// Crowd Baby, Crowd Explorer, Crowd Collaborator and Crowd Royalty. The app
/// never derives it from the points; it shows what the API sends (`tier`).
enum TierUsuario {
  crowdBaby('Crowd Baby', 'assets/images/tier_crowd_baby.png'),
  crowdExplorer('Crowd Explorer', 'assets/images/tier_crowd_explorer.png'),
  crowdCollaborator(
    'Crowd Collaborator',
    'assets/images/tier_crowd_collaborator.png',
  ),
  crowdRoyalty('Crowd Royalty', 'assets/images/tier_crowd_royalty.png');

  /// Name shown to the user.
  final String nombre;

  /// Asset path of the badge (bronze, silver, gold, platinum).
  final String insignia;

  const TierUsuario(this.nombre, this.insignia);

  /// Null or unknown values mean the entry tier, the one of a user with no
  /// points yet.
  static TierUsuario desdeApi(Object? crudo) =>
      enumDesdeApi(values, crudo) ?? crowdBaby;
}
