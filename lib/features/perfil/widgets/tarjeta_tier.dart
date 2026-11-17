import 'package:flutter/material.dart';

import '../../../core/models/tier_usuario.dart';
import '../../../theme/app_colors.dart';

/// CRO-74: the user's tier on the profile (design-system §5): a brand blue
/// card with the badge, the «TU TIER» eyebrow and the tier name, plus the
/// points the backend sent on the right (D5).
class TarjetaTier extends StatelessWidget {
  static const Key clave = Key('perfil-tier');

  /// Side of the badge, in logical pixels.
  static const double ladoInsignia = 52;

  final TierUsuario tier;
  final int puntos;

  const TarjetaTier(this.tier, {required this.puntos}) : super(key: clave);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    child: Container(
      key: const ValueKey('perfil-tier-fondo'),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 20, 14),
      child: Row(
        children: [
          Container(
            width: ladoInsignia,
            height: ladoInsignia,
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              tier.insignia,
              fit: BoxFit.contain,
              semanticLabel: 'Insignia ${tier.nombre}',
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TU TIER',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.72,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tier.nombre,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$puntos',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  color: Colors.white,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const Text(
                'puntos',
                style: TextStyle(fontSize: 12.5, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
