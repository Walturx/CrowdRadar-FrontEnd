import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/rutas.dart';
import '../../../core/models/moderacion.dart';
import '../../../core/utils/formato_fecha.dart';
import '../../../core/widgets/cargando.dart';
import '../../../core/widgets/chip_saturacion.dart';
import '../../../core/widgets/estado_error.dart';
import '../../../core/widgets/estado_vacio.dart';
import '../../../core/widgets/mostrar_aviso.dart';
import '../../../theme/app_colors.dart';
import '../data/moderacion_repository.dart';
import '../widgets/etiqueta_motivo.dart';
import 'denunciados_cubit.dart';
import 'denunciados_state.dart';

/// HU 7.1: queue of reported reports (`/admin/reportes`).
class DenunciadosPage extends StatelessWidget {
  static const String tituloVacio = 'Sin denuncias pendientes';
  static const String mensajeVacio =
      'No hay reportes denunciados por revisar. ¡La comunidad está al día!';

  const DenunciadosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          DenunciadosCubit(context.read<ModeracionRepository>())..cargar(),
      child: BlocConsumer<DenunciadosCubit, DenunciadosState>(
        listenWhen: (a, b) => b is DenunciadosCargado && b.aviso != null,
        listener: (context, state) {
          mostrarAviso(context, (state as DenunciadosCargado).aviso!);
          context.read<DenunciadosCubit>().descartarAviso();
        },
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Reportes denunciados')),
          body: switch (state) {
            DenunciadosCargando() => const Cargando(),
            DenunciadosError() => EstadoError(
              mensaje: state.mensaje,
              onReintentar: () => context.read<DenunciadosCubit>().cargar(),
            ),
            DenunciadosCargado() when state.estaVacia => const EstadoVacio(
              icon: Icons.shield_outlined,
              title: tituloVacio,
              subtitle: mensajeVacio,
            ),
            DenunciadosCargado() => _Lista(state),
          },
        ),
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  final DenunciadosCargado estado;

  const _Lista(this.estado);

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DenunciadosCubit>();
    return RefreshIndicator(
      onRefresh: cubit.refrescar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${estado.total} REPORTES POR REVISAR',
            style: const TextStyle(
              fontSize: 12,
              letterSpacing: 0.6,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          for (final r in estado.reportes) _Tarjeta(r),
          if (estado.hayMas)
            Center(
              child: estado.cargandoMas
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    )
                  : TextButton(
                      onPressed: cubit.cargarMas,
                      child: const Text('Cargar más'),
                    ),
            ),
        ],
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  final ReporteDenunciado reporte;

  const _Tarjeta(this.reporte);

  @override
  Widget build(BuildContext context) {
    final fecha = reporte.fechaHora;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reporte.lugar.nombre,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              fecha == null
                  ? reporte.autor.nombreCorto
                  : '${reporte.autor.nombreCorto} · ${haceCuanto(fecha)}',
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ChipSaturacion(nivel: reporte.nivel),
                const SizedBox(width: 8),
                Text(textoDenuncias(reporte.pendientes)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _revisar(context),
                child: const Text('Revisar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The review screen answers `true` once the report left the queue.
  Future<void> _revisar(BuildContext context) async {
    final cubit = context.read<DenunciadosCubit>();
    final salio = await context.push<bool>(
      Rutas.adminReporte(reporte.reporteId),
    );
    if (salio == true) cubit.retirar(reporte.reporteId);
    await cubit.refrescar();
  }
}
