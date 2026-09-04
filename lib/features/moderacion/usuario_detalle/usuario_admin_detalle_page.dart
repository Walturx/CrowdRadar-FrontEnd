import 'package:flutter/widgets.dart';

import '../../../core/widgets/pagina_provisional.dart';

/// Placeholder owned by M6 (`/admin/usuarios/:id`).
class UsuarioAdminDetallePage extends StatelessWidget {
  final int usuarioId;

  const UsuarioAdminDetallePage({super.key, required this.usuarioId});

  @override
  Widget build(BuildContext context) => PaginaProvisional(
    titulo: 'Detalle del usuario',
    referencia: 'Usuario #$usuarioId',
  );
}
