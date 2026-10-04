import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/analitica.dart';
import '../../../core/widgets/chip_saturacion.dart';
import '../data/analitica_repository.dart';
import '../widgets/vista_analitica.dart';
import 'mejor_horario_cubit.dart';

/// HU 6.3: the least crowded hours to visit a place.
class MejorHorarioPage extends StatelessWidget {
  final int lugarId;

  const MejorHorarioPage({super.key, required this.lugarId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          MejorHorarioCubit(context.read<AnaliticaRepository>(), lugarId)
            ..cargar(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Mejor horario')),
        body: VistaAnalitica<MejorHorarioCubit, MejorHorario>(
          tituloSinDatos: 'Sin recomendación todavía',
          mensajeSinDatos:
              'No existen datos suficientes para generar la recomendación.',
          esSintetico: (m) => m.sintetico,
          construir: (context, m) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const EtiquetaSeccion('MEJOR HORA PARA VISITAR'),
              _Franja(m.franjas.first, destacada: true),
              const SizedBox(height: 8),
              const Text(
                'Es el horario con menor afluencia. Planifica tu visita entonces.',
              ),
              if (m.franjas.length > 1) ...[
                const EtiquetaSeccion('OTRAS OPCIONES'),
                for (final f in m.franjas.skip(1)) _Franja(f),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Franja extends StatelessWidget {
  final FranjaHoraria franja;
  final bool destacada;

  const _Franja(this.franja, {this.destacada = false});

  @override
  Widget build(BuildContext context) {
    final rango =
        '${etiquetaHora(franja.horaInicio)} - ${etiquetaHora(franja.horaFin)}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              rango,
              style: TextStyle(
                fontSize: destacada ? 28 : 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ChipSaturacion(nivel: franja.nivel),
        ],
      ),
    );
  }
}
