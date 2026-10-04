import 'package:flutter/material.dart';

import '../../../core/models/nivel_saturacion.dart';
import '../../../core/widgets/chip_saturacion.dart';
import '../../../theme/app_colors.dart';

/// Color key of the map markers.
class LeyendaSaturacion extends StatelessWidget {
  const LeyendaSaturacion({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final nivel in NivelSaturacion.values) ...[
            Icon(Icons.circle, size: 10, color: ChipSaturacion.colorDe(nivel)),
            const SizedBox(width: 4),
            Text(
              ChipSaturacion.etiquetaDe(nivel),
              style: const TextStyle(fontSize: 12, color: AppColors.text),
            ),
            if (nivel != NivelSaturacion.values.last) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}
