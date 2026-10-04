import 'package:flutter/material.dart';

/// Cancel / confirm dialog shared by destructive actions. Resolves to true
/// only when the user confirms (dismissing counts as cancelling).
Future<bool> confirmarAccion(
  BuildContext context, {
  required String titulo,
  String? contenido,
  required String etiquetaConfirmar,
}) async {
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (dialogo) => AlertDialog(
      title: Text(titulo),
      content: contenido == null ? null : Text(contenido),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogo, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogo, true),
          child: Text(etiquetaConfirmar),
        ),
      ],
    ),
  );
  return confirmado ?? false;
}
