import 'package:flutter/material.dart';

import '../../../core/models/analitica.dart';
import '../../../core/models/nivel_saturacion.dart';
import '../../../core/widgets/chip_saturacion.dart';
import '../../../theme/app_colors.dart';

/// Plain bar chart (no charting dependency): one bar per point, height and
/// colour follow the crowding value (1 = tranquilo .. 3 = saturado).
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Tooltip(
                      message: '${p.etiqueta}: ${p.valor.toStringAsFixed(1)}',
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
