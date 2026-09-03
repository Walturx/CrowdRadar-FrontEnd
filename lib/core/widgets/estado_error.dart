import 'package:flutter/material.dart';

/// Error message with an optional retry button.
class EstadoError extends StatelessWidget {
  final String mensaje;
  final VoidCallback? onReintentar;

  const EstadoError({super.key, required this.mensaje, this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(mensaje),
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
