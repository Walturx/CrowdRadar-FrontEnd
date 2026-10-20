import 'package:flutter/material.dart';

import '../../../core/models/moderacion.dart';
import '../../../theme/app_colors.dart';

/// Account status of a user: "Activo" or "Suspendido" (HU 7.2 / 7.4).
class ChipEstadoCuenta extends StatelessWidget {
  final EstadoCuenta estado;

  const ChipEstadoCuenta({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    final suspendido = estado == EstadoCuenta.suspendido;
    final color = suspendido ? AppColors.danger : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        suspendido ? 'Suspendido' : 'Activo',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
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
