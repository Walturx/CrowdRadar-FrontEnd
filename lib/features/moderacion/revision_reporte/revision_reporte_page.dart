import 'package:flutter/widgets.dart';

import '../../../core/widgets/pagina_provisional.dart';

/// Placeholder owned by M6 (`/admin/reportes/:id`).
class RevisionReportePage extends StatelessWidget {
  final int reporteId;

  const RevisionReportePage({super.key, required this.reporteId});

  @override
  Widget build(BuildContext context) => PaginaProvisional(
    titulo: 'Revisión del reporte',
    referencia: 'Reporte #$reporteId',
  );
}
