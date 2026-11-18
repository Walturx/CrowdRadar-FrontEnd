import 'package:flutter/material.dart';

import '../../../core/models/nivel_saturacion.dart';
import '../../../core/widgets/chip_saturacion.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_shadows.dart';

/// Minimal map key (decision D3): the level chips already carry the meter,
/// so only the gray "Sin información" pins need a key of their own.
class LeyendaSaturacion extends StatelessWidget {
  const LeyendaSaturacion({super.key});

  @override
  Widget build(BuildContext context) {
    const nivel = NivelSaturacion.sinInformacion;
    return Container(
      key: const ValueKey('leyenda-sin-informacion'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.floating,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: ChipSaturacion.colorDe(nivel),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            ChipSaturacion.etiquetaDe(nivel),
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
