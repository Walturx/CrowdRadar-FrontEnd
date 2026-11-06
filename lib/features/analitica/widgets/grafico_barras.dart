import 'package:flutter/material.dart';

import '../../../core/models/analitica.dart';
import '../../../core/models/nivel_saturacion.dart';
import '../../../core/widgets/chip_saturacion.dart';
import '../../../theme/app_colors.dart';

/// Plain bar chart (no charting dependency): one bar per point, height and
/// colour follow the crowding value (1 = tranquilo .. 3 = saturado).
///
/// The bars are spread evenly, so [puntos] must hold every slot of the axis:
/// the backend sends the 24 hours, or every day of the range, and a slot
/// without reports comes with `muestras` 0 and is drawn empty.
class GraficoBarras extends StatelessWidget {
  static const double _alto = 120;
  static const List<String> ejeHoras = ['0h', '6h', '12h', '18h', '23h'];

  final List<PuntoSerie> puntos;

  /// Labels under the bars, spread evenly; defaults to the first and last.
  final List<String>? eje;

  const GraficoBarras({super.key, required this.puntos, this.eje});

  @override
  Widget build(BuildContext context) {
    final etiquetas =
        eje ??
        [
          if (puntos.isNotEmpty) puntos.first.etiqueta,
          if (puntos.length > 1) puntos.last.etiqueta,
        ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _alto,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final p in puntos)
                Expanded(
                  // The tooltip covers the whole column, not just the bar,
                  // so an empty slot (a bar 0 high) can still be pressed.
                  child: Tooltip(
                    message: p.muestras == 0
                        ? '${p.etiqueta}: sin reportes'
                        : '${p.etiqueta}: ${p.valor.toStringAsFixed(1)}',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          key: const Key('barra-saturacion'),
                          height: _alto * (p.valor.clamp(0.0, 3.0) / 3),
                          color: ChipSaturacion.colorDe(
                            NivelSaturacion.desdePromedio(p.valor),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final e in etiquetas)
              Text(
                e,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Legend of the bar colours.
class LeyendaBarras extends StatelessWidget {
  const LeyendaBarras({super.key});

  @override
  Widget build(BuildContext context) => const Wrap(
    spacing: 8,
    children: [
      ChipSaturacion(nivel: NivelSaturacion.tranquilo),
      ChipSaturacion(nivel: NivelSaturacion.moderado),
      ChipSaturacion(nivel: NivelSaturacion.saturado),
    ],
  );
}
