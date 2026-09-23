import 'package:flutter/material.dart';

/// Error message (optionally under a bold [titulo]) with an optional retry button.
class EstadoError extends StatelessWidget {
  final String? titulo;
  final String mensaje;
  final VoidCallback? onReintentar;

  const EstadoError({
    super.key,
    this.titulo,
    required this.mensaje,
    this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
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
      ),
    );
  }
}
