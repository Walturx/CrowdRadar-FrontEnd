import 'package:flutter/material.dart';

import 'estado_vacio.dart';

/// Placeholder body for a route whose stream has not built the screen yet.
/// The owning stream replaces the page class' body, never the route.
class PaginaProvisional extends StatelessWidget {
  static const String textoPendiente = 'Pantalla en construcción';

  final String titulo;

  /// Identifies the opened resource, e.g. `Lugar #7`.
  final String? referencia;

  const PaginaProvisional({super.key, required this.titulo, this.referencia});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: EstadoVacio(
        icon: Icons.construction_outlined,
        title: titulo,
        subtitle: referencia == null
            ? textoPendiente
            : '$referencia · $textoPendiente',
      ),
    );
  }
}
