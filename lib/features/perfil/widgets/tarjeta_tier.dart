import 'package:flutter/material.dart';

import '../../../core/models/tier_usuario.dart';
import '../../../theme/app_colors.dart';

/// CRO-74: the user's tier on the profile, its badge next to its name. It shows
/// the tier the backend sent; the points and the progress to the next tier are
/// out of scope until the team decides how to show them.
class TarjetaTier extends StatelessWidget {
  static const Key clave = Key('perfil-tier');

  /// Side of the badge, in logical pixels.
  static const double ladoInsignia = 56;

  final TierUsuario tier;

  const TarjetaTier(this.tier) : super(key: clave);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Image.asset(
            tier.insignia,
            width: ladoInsignia,
            height: ladoInsignia,
            fit: BoxFit.contain,
            semanticLabel: 'Insignia ${tier.nombre}',
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tier',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tier.nombre,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
