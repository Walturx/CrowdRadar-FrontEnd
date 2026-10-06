import 'package:flutter/material.dart';

import '../../../core/models/validacion.dart';
import '../../../theme/app_colors.dart';

/// Reliability of a report (HU 5.2): "86%" and "Confiabilidad Alta", or a
/// short note while there are too few votes.
class InsigniaConfiabilidad extends StatelessWidget {
  static const String textoInsuficiente = 'Aún no hay suficientes validaciones';

  final Confiabilidad confiabilidad;

  const InsigniaConfiabilidad({super.key, required this.confiabilidad});

  static Color colorDe(NivelConfiabilidad nivel) => switch (nivel) {
    NivelConfiabilidad.alta => AppColors.success,
    NivelConfiabilidad.media => AppColors.warning,
    NivelConfiabilidad.baja => AppColors.danger,
    NivelConfiabilidad.insuficiente => AppColors.textMuted,
  };

  static String etiquetaDe(NivelConfiabilidad nivel) => switch (nivel) {
    NivelConfiabilidad.alta => 'Confiabilidad Alta',
    NivelConfiabilidad.media => 'Confiabilidad Media',
    NivelConfiabilidad.baja => 'Confiabilidad Baja',
    NivelConfiabilidad.insuficiente => textoInsuficiente,
  };

  @override
  Widget build(BuildContext context) {
    final color = colorDe(confiabilidad.nivel);
    final porcentaje = confiabilidad.porcentaje;
    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (porcentaje != null)
          Text(
            '${porcentaje.round()}%',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        Text(
          etiquetaDe(confiabilidad.nivel),
          style: TextStyle(fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}
