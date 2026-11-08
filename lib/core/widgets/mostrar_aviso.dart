import 'package:flutter/material.dart';

/// Shows [texto] in a snack bar, replacing the one on screen. With
/// [etiquetaAccion] the bar offers an action that runs [alAccionar]; with
/// [alLado] that widget sits beside the text (e.g. the voter's tier).
void mostrarAviso(
  BuildContext context,
  String texto, {
  String? etiquetaAccion,
  VoidCallback? alAccionar,
  Widget? alLado,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: alLado == null
            ? Text(texto)
            : Row(
                children: [
                  Expanded(child: Text(texto)),
                  const SizedBox(width: 12),
                  alLado,
                ],
              ),
        action: etiquetaAccion == null
            ? null
            : SnackBarAction(
                label: etiquetaAccion,
                onPressed: alAccionar ?? () {},
              ),
      ),
    );
}
