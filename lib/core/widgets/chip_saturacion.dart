import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../models/nivel_saturacion.dart';

/// Colored label for a crowding level.
class ChipSaturacion extends StatelessWidget {
  final NivelSaturacion nivel;

  const ChipSaturacion({super.key, required this.nivel});

  static Color colorDe(NivelSaturacion nivel) => switch (nivel) {
    NivelSaturacion.tranquilo => AppColors.success,
    NivelSaturacion.moderado => AppColors.warning,
    NivelSaturacion.saturado => AppColors.danger,
    NivelSaturacion.sinInformacion => AppColors.textMuted,
  };

  static String etiquetaDe(NivelSaturacion nivel) => switch (nivel) {
    NivelSaturacion.tranquilo => 'Tranquilo',
    NivelSaturacion.moderado => 'Moderado',
    NivelSaturacion.saturado => 'Saturado',
    NivelSaturacion.sinInformacion => 'Sin información',
  };

  @override
  Widget build(BuildContext context) {
    final color = colorDe(nivel);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        etiquetaDe(nivel),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
