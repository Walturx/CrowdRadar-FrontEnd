import 'package:flutter/widgets.dart';

import '../../../core/widgets/pagina_provisional.dart';

/// Placeholder owned by M4 (`/mapa/lugares/:id/historial`).
class HistorialPage extends StatelessWidget {
  final int lugarId;

  const HistorialPage({super.key, required this.lugarId});

  @override
  Widget build(BuildContext context) => PaginaProvisional(
    titulo: 'Historial de aforo',
    referencia: 'Lugar #$lugarId',
  );
}
