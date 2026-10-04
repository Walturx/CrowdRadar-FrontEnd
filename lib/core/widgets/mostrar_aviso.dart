import 'package:flutter/material.dart';

/// Shows [texto] in a snack bar, replacing the one on screen. With
/// [etiquetaAccion] the bar offers an action that runs [alAccionar].
void mostrarAviso(
  BuildContext context,
  String texto, {
  String? etiquetaAccion,
  VoidCallback? alAccionar,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(texto),
        action: etiquetaAccion == null
            ? null
            : SnackBarAction(
                label: etiquetaAccion,
                onPressed: alAccionar ?? () {},
              ),
      ),
    );
}
