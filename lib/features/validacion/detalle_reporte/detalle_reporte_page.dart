import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/validacion.dart';
import '../../../core/widgets/cargando.dart';
import '../../../core/widgets/chip_saturacion.dart';
import '../../../core/widgets/estado_error.dart';
import '../../../core/widgets/mostrar_aviso.dart';
import '../../../theme/app_colors.dart';
import '../data/validacion_repository.dart';
import '../denunciar/denunciar_sheet.dart';
import '../widgets/chip_estado_validacion.dart';
import '../widgets/insignia_confiabilidad.dart';
import 'detalle_reporte_cubit.dart';
import 'detalle_reporte_state.dart';

/// HU 5.1 c2 / 5.2 / 5.4: a report with its reliability, my vote and the
/// option to report it (`/validar/reportes/:id`).
class DetalleReportePage extends StatelessWidget {
  /// HU 5.2 c3.
  static const String textoInsuficiente =
      'Aún no hay información suficiente para determinar la confiabilidad.';

  final int reporteId;

  const DetalleReportePage({super.key, required this.reporteId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          DetalleReporteCubit(context.read<ValidacionRepository>(), reporteId)
            ..cargar(),
      child: BlocConsumer<DetalleReporteCubit, DetalleState>(
        listenWhen: (a, b) => b is DetalleCargado && b.aviso != null,
        listener: (context, state) {
          mostrarAviso(context, (state as DetalleCargado).aviso!);
          context.read<DetalleReporteCubit>().descartarAviso();
        },
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Detalle del reporte')),
          body: switch (state) {
            DetalleCargando() => const Cargando(),
            DetalleError() => EstadoError(
              mensaje: state.mensaje,
              onReintentar: () => context.read<DetalleReporteCubit>().cargar(),
            ),
            DetalleCargado() => _Contenido(state, reporteId),
          },
        ),
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  final DetalleCargado estado;
  final int reporteId;

  const _Contenido(this.estado, this.reporteId);

  @override
  Widget build(BuildContext context) {
    final d = estado.detalle;
    final c = d.confiabilidad;
    final cubit = context.read<DetalleReporteCubit>();
    final voto = d.miValidacion;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          d.lugar.nombre,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        Row(
          children: [
            ChipSaturacion(nivel: d.nivel),
            const SizedBox(width: 8),
            ChipEstadoValidacion(estado: d.estadoValidacion),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'CONFIABILIDAD DEL REPORTE',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        InsigniaConfiabilidad(confiabilidad: c),
        if (c.nivel == NivelConfiabilidad.insuficiente)
          const Text(DetalleReportePage.textoInsuficiente)
        else
          const Text('Basado en confirmaciones de la comunidad'),
        Text('${c.confirmaciones} confirman'),
        Text('${c.rechazos} rechazan'),
        if (c.nivel == NivelConfiabilidad.baja && c.advertencia != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              c.advertencia!,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        const SizedBox(height: 16),
        if (voto != null)
          Text(
            voto == TipoAccionValidacion.confirmar
                ? 'Tu voto: Confirmaste este reporte'
                : 'Tu voto: Rechazaste este reporte',
            style: const TextStyle(fontWeight: FontWeight.w600),
          )
        else if (!d.esPropio)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: estado.votando
                      ? null
                      : () => cubit.validar(TipoAccionValidacion.rechazar),
                  child: const Text('Rechazar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: estado.votando
                      ? null
                      : () => cubit.validar(TipoAccionValidacion.confirmar),
                  child: const Text('Confirmar'),
                ),
              ),
            ],
          ),
        const SizedBox(height: 16),
        if (d.esPropio)
          const SizedBox.shrink()
        else if (d.yaDenunciado)
          const Text('Ya denunciaste este reporte')
        else
          TextButton(
            onPressed: () async {
              final enviada = await mostrarDenunciarSheet(
                context,
                reporteId: reporteId,
              );
              if (enviada == true) cubit.cargar();
            },
            child: const Text('Denunciar reporte fraudulento'),
          ),
      ],
    );
  }
}
