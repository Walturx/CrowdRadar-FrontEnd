import 'package:flutter/widgets.dart';

import '../../../core/widgets/pagina_provisional.dart';

/// Placeholder owned by M5 (`/validar/reportes/:id`).
class DetalleReportePage extends StatelessWidget {
  final int reporteId;

  const DetalleReportePage({super.key, required this.reporteId});

  @override
  Widget build(BuildContext context) => PaginaProvisional(
    titulo: 'Detalle del reporte',
    referencia: 'Reporte #$reporteId',
  );
}
