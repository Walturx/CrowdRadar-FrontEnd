import '../../../core/widgets/lista_perezosa.dart';
import 'package:flutter/material.dart';

import '../../../core/config/entorno.dart';
import '../../../theme/app_colors.dart';

/// About screen: app name and version, the map data attribution that the
/// OpenStreetMap license requires, and the course team.
class AcercaPage extends StatelessWidget {
  static const String atribucion = '© OpenStreetMap contributors';
  static const String enlaceLicencia =
      'https://www.openstreetmap.org/copyright';
  static const String lineaEquipo =
      'Proyecto del curso Ingeniería de Software II, Universidad de Lima';

  const AcercaPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Acerca de')),
    body: ListaPerezosa.secciones(
      padding: const EdgeInsets.all(24),
      secciones: [
        const Text(
          'CrowdRadar',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Versión ${Entorno.version}',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        const SizedBox(height: 24),
        const Text(
          'Datos del mapa',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        const Text(atribucion),
        const Text('Disponibles bajo la licencia ODbL.'),
        const SelectableText(
          enlaceLicencia,
          style: TextStyle(color: AppColors.primary),
        ),
        const SizedBox(height: 24),
        const Text(lineaEquipo, style: TextStyle(color: AppColors.textMuted)),
      ],
    ),
  );
}
