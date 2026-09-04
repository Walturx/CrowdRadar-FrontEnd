import 'package:flutter/widgets.dart';

import '../../../core/widgets/pagina_provisional.dart';

/// Placeholder owned by M2 (`/mapa/lugares/:id`).
class DetalleLugarPage extends StatelessWidget {
  final int lugarId;

  const DetalleLugarPage({super.key, required this.lugarId});

  @override
  Widget build(BuildContext context) => PaginaProvisional(
    titulo: 'Detalle del lugar',
    referencia: 'Lugar #$lugarId',
  );
}
