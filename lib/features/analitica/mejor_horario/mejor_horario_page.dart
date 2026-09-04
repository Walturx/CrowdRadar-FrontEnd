import 'package:flutter/widgets.dart';

import '../../../core/widgets/pagina_provisional.dart';

/// Placeholder owned by M4 (`/mapa/lugares/:id/mejor-horario`).
class MejorHorarioPage extends StatelessWidget {
  final int lugarId;

  const MejorHorarioPage({super.key, required this.lugarId});

  @override
  Widget build(BuildContext context) =>
      PaginaProvisional(titulo: 'Mejor horario', referencia: 'Lugar #$lugarId');
}
