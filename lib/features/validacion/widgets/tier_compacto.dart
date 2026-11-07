import 'package:flutter/material.dart';

import '../../../core/models/tier_usuario.dart';

/// S23: the voter's own tier next to the "¡Gracias por validar!" thanks, its
/// badge beside its name. A compact take on the profile's tier card; the name
/// takes the text colour of where it sits (the thanks card or the snack bar).
class TierCompacto extends StatelessWidget {
  /// Side of the badge, in logical pixels.
  static const double ladoInsignia = 28;

  final TierUsuario tier;

  const TierCompacto(this.tier, {super.key});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Image.asset(
        tier.insignia,
        width: ladoInsignia,
        height: ladoInsignia,
        fit: BoxFit.contain,
        semanticLabel: 'Insignia ${tier.nombre}',
      ),
      const SizedBox(width: 6),
      Text(tier.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
    ],
  );
}
