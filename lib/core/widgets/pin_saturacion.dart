import 'package:flutter/material.dart';

import '../models/nivel_saturacion.dart';
import 'chip_saturacion.dart';

/// Map pin colored by crowding level.
class PinSaturacion extends StatelessWidget {
  final NivelSaturacion nivel;
  final String? etiqueta;
  final VoidCallback? onTap;

  const PinSaturacion({
    super.key,
    required this.nivel,
    this.etiqueta,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: etiqueta ?? '',
        child: Icon(
          Icons.location_on,
          color: ChipSaturacion.colorDe(nivel),
          size: 40,
        ),
      ),
    );
  }
}
