import 'package:flutter/material.dart';

import '../../../core/models/analitica.dart';
import '../../../core/models/nivel_saturacion.dart';
import '../../../core/widgets/chip_saturacion.dart';
import '../../../theme/app_colors.dart';

/// Plain bar chart (no charting dependency): one bar per point, height and
/// colour (the level's `dot`) follow the crowding value (1 = tranquilo ..
/// 3 = saturado), with a rounded top.
///
/// The bars are spread evenly, so [puntos] must hold every slot of the axis:
/// the backend sends the 24 hours, or every day of the range, and a slot
/// without reports comes with `muestras` 0 and is drawn as a short stub in the
/// border color.
class GraficoBarras extends StatelessWidget {
  static const double _alto = 120;

  /// Height of the stub drawn for a slot without reports (design-system §5).
  static const double altoSinReportes = 6;
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
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          key: const Key('barra-saturacion'),
                          height: p.muestras == 0
                              ? altoSinReportes
                              : _alto * (p.valor.clamp(0.0, 3.0) / 3),
                          decoration: BoxDecoration(
                            color: p.muestras == 0
                                ? AppColors.border
                                : ChipSaturacion.colorDe(
                                    NivelSaturacion.desdePromedio(p.valor),
                                  ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
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
                  fontSize: 11.5,
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Legend of the bar colours: a 10 px square in each level's `dot` color
/// beside its name.
class LeyendaBarras extends StatelessWidget {
  const LeyendaBarras({super.key});

  static const List<NivelSaturacion> _niveles = [
    NivelSaturacion.tranquilo,
    NivelSaturacion.moderado,
    NivelSaturacion.saturado,
  ];

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 14,
    runSpacing: 6,
    children: [
      for (final nivel in _niveles)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              key: ValueKey('leyenda-cuadro-${nivel.name}'),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: ChipSaturacion.colorDe(nivel),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              ChipSaturacion.etiquetaDe(nivel),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
    ],
  );
}
