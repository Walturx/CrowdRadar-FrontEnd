import 'package:flutter/material.dart';

import '../../../core/models/moderacion.dart';
import '../../../theme/app_colors.dart';

/// Account status of a user: "Activo" or "Suspendido" (HU 7.2 / 7.4).
///
/// Activo is the success state (green text with a green dot); Suspendido is a
/// system error state (danger on dangerBg with a block icon), design-system
/// §2.3.
class ChipEstadoCuenta extends StatelessWidget {
  final EstadoCuenta estado;

  const ChipEstadoCuenta({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    final suspendido = estado == EstadoCuenta.suspendido;
    final color = suspendido ? AppColors.danger : AppColors.tranquilo;
    return Container(
      key: const ValueKey('chip-estado-cuenta'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: suspendido ? AppColors.dangerBg : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (suspendido)
            const Icon(
              Icons.block,
              key: ValueKey('icono-estado-cuenta'),
              size: 14,
              color: AppColors.danger,
            )
          else
            Container(
              key: const ValueKey('punto-estado-cuenta'),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.tranquiloDot,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              suspendido ? 'Suspendido' : 'Activo',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "faltan 5 días" derived from the end of the vigente sanction.
String textoFaltan(SancionVigente? sancion, {DateTime? ahora}) {
  final dias = sancion?.diasRestantes(ahora ?? DateTime.now()) ?? 0;
  if (dias <= 0) return '';
  return dias == 1 ? 'faltan 1 día' : 'faltan $dias días';
}

/// "Suspendido · faltan 5 días", or just the label without a vigente sanction.
String textoSuspension(
  String etiqueta,
  SancionVigente? sancion, {
  DateTime? ahora,
}) {
  final faltan = textoFaltan(sancion, ahora: ahora);
  return faltan.isEmpty ? etiqueta : '$etiqueta · $faltan';
}
