import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/rutas.dart';
import '../../../core/models/moderacion.dart';
import '../../../core/utils/formato_fecha.dart';
import '../../../core/widgets/cargando.dart';
import '../../../core/widgets/cerrar_sesion.dart';
import '../../../core/widgets/chip_saturacion.dart';
import '../../../core/widgets/estado_error.dart';
import '../../../core/widgets/estado_vacio.dart';
import '../../../core/widgets/lista_perezosa.dart';
import '../../../core/widgets/mostrar_aviso.dart';
import '../../../core/utils/contador.dart';
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
          appBar: AppBar(
            title: const Text('Reportes denunciados'),
            actions: const [BotonCerrarSesion()],
          ),
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
      child: ListaPerezosa(
        padding: const EdgeInsets.all(16),
        cabecera: [
          Text(
            contador(
              estado.total,
              'REPORTE POR REVISAR',
              'REPORTES POR REVISAR',
            ),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.72,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
        ],
        cantidad: estado.reportes.length,
        idFila: (i) => estado.reportes[i].reporteId,
        fila: (_, i) => _Fila(
          estado.reportes[i],
          primera: i == 0,
          ultima: i == estado.reportes.length - 1,
        ),
        pie: [
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

/// One compact row of the grouped queue card (design-system §5 and §7).
///
/// The list is lazy, so the card is drawn row by row: every row paints its
/// top line (the card border on the first row, a divider on the others) and
/// the last row closes the card with its bottom line and rounded corners.
class _Fila extends StatelessWidget {
  static const double radio = 20;

  final ReporteDenunciado reporte;
  final bool primera;
  final bool ultima;

  const _Fila(this.reporte, {required this.primera, required this.ultima});

  @override
  Widget build(BuildContext context) {
    final fecha = reporte.fechaHora;
    final esquinas = BorderRadius.vertical(
      top: primera ? const Radius.circular(radio) : Radius.zero,
      bottom: ultima ? const Radius.circular(radio) : Radius.zero,
    );
    return ClipRRect(
      key: const ValueKey('denunciado-fila'),
      borderRadius: esquinas,
      child: ColoredBox(
        color: AppColors.border,
        child: Padding(
          padding: EdgeInsets.fromLTRB(1, 1, 1, ultima ? 1 : 0),
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: primera ? const Radius.circular(radio - 1) : Radius.zero,
              bottom: ultima ? const Radius.circular(radio - 1) : Radius.zero,
            ),
            child: ColoredBox(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reporte.lugar.nombre,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            fecha == null
                                ? reporte.autor.nombreCorto
                                : '${reporte.autor.nombreCorto} · '
                                      '${haceCuanto(fecha)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              ChipSaturacion(nivel: reporte.nivel),
                              _ChipDenuncias(reporte.pendientes),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => _revisar(context),
                      // Small filled button: overrides the theme's
                      // full-width 52 px size, keeping a 44 px touch target.
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(44, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Revisar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
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

/// Pending complaints of a report: flag icon plus its count, in danger.
class _ChipDenuncias extends StatelessWidget {
  final int cantidad;

  const _ChipDenuncias(this.cantidad);

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('chip-denuncias'),
    height: ChipSaturacion.alto,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: AppColors.dangerBg,
      borderRadius: BorderRadius.circular(ChipSaturacion.alto / 2),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.flag_outlined, size: 14, color: AppColors.danger),
        const SizedBox(width: 4),
        Text(
          textoDenuncias(cantidad),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.danger,
          ),
        ),
      ],
    ),
  );
}
