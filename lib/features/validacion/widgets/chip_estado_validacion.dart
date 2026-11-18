import 'package:flutter/material.dart';

import '../../../core/models/validacion.dart';
import '../../../theme/app_colors.dart';

/// Validation status of one of my reports (HU 5.3). Also used by the report
/// history (`MisReportesPage`).
class ChipEstadoValidacion extends StatelessWidget {
  final EstadoValidacion estado;

  const ChipEstadoValidacion({super.key, required this.estado});

  /// Each estado is told apart by its icon; the colors stay neutral because
  /// green, amber and red belong to saturation levels (decision D6).
  static IconData iconoDe(EstadoValidacion estado) => switch (estado) {
    EstadoValidacion.validado => Icons.check_circle_outline,
    EstadoValidacion.enValidacion => Icons.hourglass_empty,
    EstadoValidacion.rechazado => Icons.cancel_outlined,
    EstadoValidacion.sinValidaciones => Icons.remove_circle_outline,
  };

  static String etiquetaDe(EstadoValidacion estado) => switch (estado) {
    EstadoValidacion.validado => 'Validado',
    EstadoValidacion.enValidacion => 'En validación',
    EstadoValidacion.rechazado => 'Rechazado',
    EstadoValidacion.sinValidaciones => 'Sin validaciones',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.sinDatosBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconoDe(estado),
            key: const ValueKey('icono-estado-validacion'),
            size: 14,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              etiquetaDe(estado),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
