import 'package:flutter/material.dart';

import 'estado_error.dart';

/// [EstadoError] as a dismissible card, meant to float over content (a map)
/// without hiding it.
class TarjetaError extends StatelessWidget {
  final String? titulo;
  final String mensaje;
  final VoidCallback? onReintentar;
  final VoidCallback onCerrar;

  const TarjetaError({
    super.key,
    this.titulo,
    required this.mensaje,
    this.onReintentar,
    required this.onCerrar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const ValueKey('tarjeta-error'),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 40, 16),
            child: EstadoError(
              titulo: titulo,
              mensaje: mensaje,
              onReintentar: onReintentar,
              compacto: true,
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              key: const ValueKey('cerrar-error'),
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Cerrar',
              onPressed: onCerrar,
            ),
          ),
        ],
      ),
    );
  }
}
