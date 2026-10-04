import 'package:flutter/widgets.dart';

import '../../../core/widgets/pagina_provisional.dart';

/// Placeholder owned by M4 (`/mapa/lugares/:id/comparar`).
class CompararPage extends StatelessWidget {
  final int lugarId;

  const CompararPage({super.key, required this.lugarId});

  @override
  Widget build(BuildContext context) => PaginaProvisional(
    titulo: 'Comparar periodos',
    referencia: 'Lugar #$lugarId',
  );
}
