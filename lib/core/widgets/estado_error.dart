import 'package:flutter/material.dart';

/// Error message (optionally under a bold [titulo]) with an optional retry button.
class EstadoError extends StatelessWidget {
  final String? titulo;
  final String mensaje;
  final VoidCallback? onReintentar;

  /// Takes only the height it needs instead of centring in the whole space.
  final bool compacto;

  const EstadoError({
    super.key,
    this.titulo,
    required this.mensaje,
    this.onReintentar,
    this.compacto = false,
  });

  @override
  Widget build(BuildContext context) {
    final contenido = Column(
      mainAxisSize: compacto ? MainAxisSize.min : MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (titulo != null) ...[
          Text(
            titulo!,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
        ],
        Text(mensaje, textAlign: TextAlign.center),
        if (onReintentar != null) ...[
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onReintentar,
            child: const Text('Reintentar'),
          ),
        ],
      ],
    );
    return compacto ? contenido : Center(child: contenido);
  }
}
