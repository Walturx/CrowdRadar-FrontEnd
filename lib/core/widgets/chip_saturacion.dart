import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../models/nivel_saturacion.dart';
import 'medidor_nivel.dart';

/// Level pill (design-system §5): 28 px high, the bar meter plus the level
/// name, in the level's `fg` color on its `bg` color. The level never relies
/// on color alone.
class ChipSaturacion extends StatelessWidget {
  static const double alto = 28;

  final NivelSaturacion nivel;

  const ChipSaturacion({super.key, required this.nivel});

  /// The level's `dot` color, used by pins and charts.
  static Color colorDe(NivelSaturacion nivel) => switch (nivel) {
    NivelSaturacion.tranquilo => AppColors.tranquiloDot,
    NivelSaturacion.moderado => AppColors.moderadoDot,
    NivelSaturacion.saturado => AppColors.saturadoDot,
    NivelSaturacion.sinInformacion => AppColors.sinDatosDot,
  };

  /// The level's text color (`fg`).
  static Color fgDe(NivelSaturacion nivel) => switch (nivel) {
    NivelSaturacion.tranquilo => AppColors.tranquilo,
    NivelSaturacion.moderado => AppColors.moderado,
    NivelSaturacion.saturado => AppColors.saturado,
    NivelSaturacion.sinInformacion => AppColors.sinDatos,
  };

  /// The level's background color (`bg`).
  static Color bgDe(NivelSaturacion nivel) => switch (nivel) {
    NivelSaturacion.tranquilo => AppColors.tranquiloBg,
    NivelSaturacion.moderado => AppColors.moderadoBg,
    NivelSaturacion.saturado => AppColors.saturadoBg,
    NivelSaturacion.sinInformacion => AppColors.sinDatosBg,
  };

  static String etiquetaDe(NivelSaturacion nivel) => switch (nivel) {
    NivelSaturacion.tranquilo => 'Tranquilo',
    NivelSaturacion.moderado => 'Moderado',
    NivelSaturacion.saturado => 'Saturado',
    NivelSaturacion.sinInformacion => 'Sin información',
  };

  /// Short description of a level (design-system §2.2).
  static String descripcionDe(NivelSaturacion nivel) => switch (nivel) {
    NivelSaturacion.tranquilo => 'Hay espacio, poca gente',
    NivelSaturacion.moderado => 'Algo concurrido',
    NivelSaturacion.saturado => 'Lleno, mucha gente',
    NivelSaturacion.sinInformacion => 'Sin reportes recientes',
  };

  @override
  Widget build(BuildContext context) {
    final fg = fgDe(nivel);
    return Container(
      key: const ValueKey('chip-saturacion'),
      height: alto,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bgDe(nivel),
        borderRadius: BorderRadius.circular(alto / 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MedidorNivel(nivel: nivel, color: fg),
          const SizedBox(width: 6),
          // Shrinks with an ellipsis instead of overflowing a narrow row.
          Flexible(
            child: Text(
              etiquetaDe(nivel),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
