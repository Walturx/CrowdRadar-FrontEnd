import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/validacion.dart';
import '../../../core/utils/formato_fecha.dart';
import '../../../core/widgets/cargando.dart';
import '../../../core/widgets/chip_saturacion.dart';
import '../../../core/widgets/estado_error.dart';
import '../../../theme/app_colors.dart';
import '../data/validacion_repository.dart';
import '../widgets/chip_estado_validacion.dart';
import 'estado_validacion_cubit.dart';
import 'estado_validacion_state.dart';

/// HU 5.3: confirmations and rejections of my reports, filterable by estado.
class EstadoValidacionPage extends StatelessWidget {
  /// HU 5.3 c3.
  static const String sinValidaciones =
      'Todavía no existen validaciones registradas.';
  static const String sinCoincidencias = 'No hay reportes con este estado.';

  const EstadoValidacionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          EstadoValidacionCubit(context.read<ValidacionRepository>())..cargar(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Estado de mis reportes')),
        body: BlocBuilder<EstadoValidacionCubit, EstadoValidacionState>(
          builder: (context, state) => switch (state) {
            EstadoValidacionCargando() => const Cargando(),
            EstadoValidacionError() => EstadoError(
              mensaje: state.mensaje,
              onReintentar: () =>
                  context.read<EstadoValidacionCubit>().cargar(),
            ),
            EstadoValidacionCargado() => _Lista(state),
          },
        ),
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  final EstadoValidacionCargado estado;

  const _Lista(this.estado);

  @override
  Widget build(BuildContext context) {
    final visibles = estado.visibles;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            children: [
              for (final f in FiltroEstadoValidacion.values)
                ChoiceChip(
                  label: Text(f.etiqueta),
                  selected: estado.filtro == f,
                  onSelected: (_) =>
                      context.read<EstadoValidacionCubit>().filtrar(f),
                ),
            ],
          ),
        ),
        if (estado.errorActualizacion != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              estado.errorActualizacion!,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        if (visibles.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              estado.reportes.isEmpty
                  ? EstadoValidacionPage.sinValidaciones
                  : EstadoValidacionPage.sinCoincidencias,
              textAlign: TextAlign.center,
            ),
          ),
        for (final r in visibles) _Fila(r),
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  final EstadoReporteValidacion reporte;

  const _Fila(this.reporte);

  @override
  Widget build(BuildContext context) {
    final fecha = reporte.fechaHora;
    return ListTile(
      title: Text(reporte.lugar.nombre),
      subtitle: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ChipSaturacion(nivel: reporte.nivel),
          if (fecha != null) Text(haceCuanto(fecha)),
          Text(
            reporte.estadoValidacion == EstadoValidacion.sinValidaciones
                ? EstadoValidacionPage.sinValidaciones
                : '${reporte.confirmaciones} confirman · ${reporte.rechazos} rechazan',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
      trailing: ChipEstadoValidacion(estado: reporte.estadoValidacion),
    );
  }
}
