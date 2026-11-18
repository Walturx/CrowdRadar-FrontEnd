import 'package:flutter/material.dart';

import '../../../core/models/validacion.dart';
import '../../../theme/app_colors.dart';

/// Reliability of a report (HU 5.2): "86%" and "Confiabilidad Alta", or a
/// short note while there are too few votes.
class InsigniaConfiabilidad extends StatelessWidget {
  static const String textoInsuficiente = 'Aún no hay suficientes validaciones';

  final Confiabilidad confiabilidad;

  const InsigniaConfiabilidad({super.key, required this.confiabilidad});

  /// Each nivel is told apart by its icon; the colors stay neutral because
  /// green, amber and red belong to saturation levels (decision D6).
  static IconData iconoDe(NivelConfiabilidad nivel) => switch (nivel) {
    NivelConfiabilidad.alta => Icons.verified_user_outlined,
    NivelConfiabilidad.media => Icons.shield_outlined,
    NivelConfiabilidad.baja => Icons.gpp_maybe_outlined,
    NivelConfiabilidad.insuficiente => Icons.hourglass_empty,
  };

  static String etiquetaDe(NivelConfiabilidad nivel) => switch (nivel) {
    NivelConfiabilidad.alta => 'Confiabilidad Alta',
    NivelConfiabilidad.media => 'Confiabilidad Media',
    NivelConfiabilidad.baja => 'Confiabilidad Baja',
    NivelConfiabilidad.insuficiente => textoInsuficiente,
  };

  @override
  Widget build(BuildContext context) {
    final porcentaje = confiabilidad.porcentaje;
    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Icon(
          iconoDe(confiabilidad.nivel),
          key: const ValueKey('icono-confiabilidad'),
          size: 20,
          color: AppColors.textSecondary,
        ),
        if (porcentaje != null)
          Text(
            '${porcentaje.round()}%',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
        Text(
          etiquetaDe(confiabilidad.nivel),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
