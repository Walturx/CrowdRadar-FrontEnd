import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/rutas.dart';
import '../../../core/models/analitica.dart';
import '../data/analitica_repository.dart';
import '../widgets/grafico_barras.dart';
import '../widgets/vista_analitica.dart';
import 'historial_lugar_cubit.dart';

/// HU 6.1: crowding history of a place, chronological.
class HistorialPage extends StatelessWidget {
  final int lugarId;

  const HistorialPage({super.key, required this.lugarId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          HistorialLugarCubit(context.read<AnaliticaRepository>(), lugarId)
            ..cargar(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Historial de aforo')),
        body: Column(
          children: [
            const _Selector(),
            Expanded(
              child: VistaAnalitica<HistorialLugarCubit, SerieSaturacion>(
                tituloSinDatos: 'Sin historial todavía',
                mensajeSinDatos:
                    'Aún no hay suficientes reportes para mostrar el comportamiento de aforo de este lugar.',
                esSintetico: (s) => s.sintetico,
                construir: (context, serie) => _Contenido(serie, lugarId),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Selector extends StatelessWidget {
  const _Selector();

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<HistorialLugarCubit>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          for (final (agrupacion, texto) in const [
            (AgrupacionHistorial.hora, 'Hoy'),
            (AgrupacionHistorial.dia, '7 días'),
          ])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(texto),
                selected: cubit.agrupacion == agrupacion,
                onSelected: (_) => cubit.seleccionar(agrupacion),
              ),
            ),
        ],
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  final SerieSaturacion serie;
  final int lugarId;

  const _Contenido(this.serie, this.lugarId);

  @override
  Widget build(BuildContext context) {
    final porHora =
        context.read<HistorialLugarCubit>().agrupacion ==
        AgrupacionHistorial.hora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Cómo varía la saturación durante el día'),
        EtiquetaSeccion(
          porHora
              ? 'SATURACIÓN POR HORA · HOY'
              : 'SATURACIÓN POR DÍA · ÚLTIMOS 7 DÍAS',
        ),
        GraficoBarras(
          puntos: serie.puntos,
          eje: porHora ? GraficoBarras.ejeHoras : null,
        ),
        const SizedBox(height: 12),
        const LeyendaBarras(),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => context.push(Rutas.comparar(lugarId)),
          child: const Text('Comparar periodos'),
        ),
        OutlinedButton(
          onPressed: () => context.push(Rutas.mejorHorario(lugarId)),
          child: const Text('Mejor horario'),
        ),
      ],
    );
  }
}
