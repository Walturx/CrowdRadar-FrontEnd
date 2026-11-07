import 'package:flutter/material.dart';

import '../../../core/models/nivel_saturacion.dart';
import '../../../core/models/validacion.dart';
import '../../../core/widgets/chip_saturacion.dart';
import 'insignia_confiabilidad.dart';

// S24: the pieces of a report card, shared by the Validar card and the report
// detail so both screens read as one design and cannot drift apart.

/// The card a report sits in: the Validar card's container and padding.
class TarjetaReporte extends StatelessWidget {
  final List<Widget> children;

  const TarjetaReporte({super.key, required this.children});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    ),
  );
}

/// The place name in bold, with an optional small label above it, an optional
/// line below it (the distance) and an optional [estado] beside it (the
/// validation state chip of the detail).
class EncabezadoReporte extends StatelessWidget {
  final String lugar;
  final String? antetitulo;
  final String? subtitulo;
  final Widget? estado;

  const EncabezadoReporte({
    super.key,
    required this.lugar,
    this.antetitulo,
    this.subtitulo,
    this.estado,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = Text(
      lugar,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
    );
    final estado = this.estado;
    final antetitulo = this.antetitulo;
    final subtitulo = this.subtitulo;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (antetitulo != null) ...[
          Text(antetitulo),
          const SizedBox(height: 8),
        ],
        if (estado == null)
          nombre
        else
          Row(
            children: [
              Expanded(child: nombre),
              const SizedBox(width: 8),
              estado,
            ],
          ),
        if (subtitulo != null) Text(subtitulo),
      ],
    );
  }
}

/// "Saturación reportada" and the saturation chip.
class SeccionSaturacion extends StatelessWidget {
  static const String etiqueta = 'Saturación reportada';

  final NivelSaturacion nivel;

  const SeccionSaturacion({super.key, required this.nivel});

  @override
  Widget build(BuildContext context) => _Seccion(
    etiqueta: etiqueta,
    children: [ChipSaturacion(nivel: nivel)],
  );
}

/// "Confiabilidad del reporte" with the coloured percentage and level, then
/// any [detalle] lines the screen adds below them.
class SeccionConfiabilidad extends StatelessWidget {
  static const String etiqueta = 'Confiabilidad del reporte';

  final Confiabilidad confiabilidad;
  final List<Widget> detalle;

  const SeccionConfiabilidad({
    super.key,
    required this.confiabilidad,
    this.detalle = const [],
  });

  @override
  Widget build(BuildContext context) => _Seccion(
    etiqueta: etiqueta,
    children: [
      InsigniaConfiabilidad(confiabilidad: confiabilidad),
      ...detalle,
    ],
  );
}

class _Seccion extends StatelessWidget {
  final String etiqueta;
  final List<Widget> children;

  const _Seccion({required this.etiqueta, required this.children});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [Text(etiqueta), ...children],
  );
}
