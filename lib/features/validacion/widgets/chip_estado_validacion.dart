import 'package:flutter/material.dart';

import '../../../core/models/validacion.dart';
import '../../../theme/app_colors.dart';

/// Validation status of one of my reports (HU 5.3). Also used by the report
/// history (`MisReportesPage`).
class ChipEstadoValidacion extends StatelessWidget {
  final EstadoValidacion estado;

  const ChipEstadoValidacion({super.key, required this.estado});

  static Color colorDe(EstadoValidacion estado) => switch (estado) {
    EstadoValidacion.validado => AppColors.success,
    EstadoValidacion.enValidacion => AppColors.warning,
    EstadoValidacion.rechazado => AppColors.danger,
    EstadoValidacion.sinValidaciones => AppColors.textMuted,
  };

  static String etiquetaDe(EstadoValidacion estado) => switch (estado) {
    EstadoValidacion.validado => 'Validado',
    EstadoValidacion.enValidacion => 'En validación',
    EstadoValidacion.rechazado => 'Rechazado',
    EstadoValidacion.sinValidaciones => 'Sin validaciones',
  };

  @override
  Widget build(BuildContext context) {
    final color = colorDe(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        etiquetaDe(estado),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
