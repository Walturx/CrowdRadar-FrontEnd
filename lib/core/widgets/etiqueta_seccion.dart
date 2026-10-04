import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Small uppercase caption that opens a section of a screen.
class EtiquetaSeccion extends StatelessWidget {
  final String texto;
  final EdgeInsetsGeometry relleno;

  const EtiquetaSeccion(
    this.texto, {
    super.key,
    this.relleno = const EdgeInsets.only(top: 20, bottom: 8),
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: relleno,
    child: Text(
      texto,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.6,
        color: AppColors.textMuted,
      ),
    ),
  );
}
