import 'package:flutter/material.dart';

import '../models/nivel_saturacion.dart';

/// Bar meter of a crowding level (design-system §5): 3 bars, 4 px wide,
/// 6/10/14 px high and 2 px apart. Filled bars are opaque, empty ones 25 %.
///
/// [escala] multiplies every size, so the big detail meter (34 px high) is
/// `escala: 34 / 14`.
class MedidorNivel extends StatelessWidget {
  static const int totalBarras = 3;
  static const double _ancho = 4;
  static const double _separacion = 2;
  static const List<double> _altos = [6, 10, 14];
  static const double _alfaVacia = 0.25;

  final NivelSaturacion nivel;
  final Color color;
  final double escala;

  const MedidorNivel({
    super.key = const ValueKey('medidor-nivel'),
    required this.nivel,
    required this.color,
    this.escala = 1,
  });

  /// How many of the 3 bars a level fills.
  static int barrasLlenasDe(NivelSaturacion nivel) => switch (nivel) {
    NivelSaturacion.tranquilo => 1,
    NivelSaturacion.moderado => 2,
    NivelSaturacion.saturado => 3,
    NivelSaturacion.sinInformacion => 0,
  };

  @override
  Widget build(BuildContext context) {
    final llenas = barrasLlenasDe(nivel);
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < totalBarras; i++) ...[
            if (i > 0) SizedBox(width: _separacion * escala),
            Container(
              key: ValueKey('medidor-barra-$i'),
              width: _ancho * escala,
              height: _altos[i] * escala,
              decoration: BoxDecoration(
                color: i < llenas ? color : color.withValues(alpha: _alfaVacia),
                borderRadius: BorderRadius.circular(1 * escala),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
