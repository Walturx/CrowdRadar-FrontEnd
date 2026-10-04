import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/analitica.dart';
import '../data/analitica_repository.dart';
import '../widgets/grafico_barras.dart';
import '../widgets/vista_analitica.dart';
import 'comparar_periodos_cubit.dart';

/// HU 6.2: weekdays against weekends, hour by hour.
class CompararPage extends StatelessWidget {
  final int lugarId;

  const CompararPage({super.key, required this.lugarId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          CompararPeriodosCubit(context.read<AnaliticaRepository>(), lugarId)
            ..cargar(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Comparar periodos')),
        body: VistaAnalitica<CompararPeriodosCubit, ComparacionPeriodos>(
          tituloSinDatos: 'Sin datos suficientes',
          mensajeSinDatos:
              'No existen datos suficientes para realizar la comparación.',
          esSintetico: (c) => c.sintetico,
          construir: (context, c) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const EtiquetaSeccion('ENTRE SEMANA'),
              GraficoBarras(
                puntos: c.periodoA.puntos,
                eje: GraficoBarras.ejeHoras,
              ),
              const EtiquetaSeccion('FIN DE SEMANA'),
              GraficoBarras(
                puntos: c.periodoB.puntos,
                eje: GraficoBarras.ejeHoras,
              ),
              const SizedBox(height: 12),
              const LeyendaBarras(),
              if (c.resumen != null) ...[
                const SizedBox(height: 16),
                Text(
                  c.resumen!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
