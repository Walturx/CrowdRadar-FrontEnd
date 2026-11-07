import '../../../core/widgets/lista_perezosa.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/validacion.dart';
import '../../../core/widgets/cargando.dart';
import '../../../core/widgets/estado_error.dart';
import '../../../core/widgets/mostrar_aviso.dart';
import '../../../theme/app_colors.dart';
import '../data/validacion_repository.dart';
import '../denunciar/denunciar_sheet.dart';
import '../widgets/chip_estado_validacion.dart';
import '../widgets/tarjeta_reporte.dart';
import '../widgets/tier_compacto.dart';
import 'detalle_reporte_cubit.dart';
import 'detalle_reporte_state.dart';

/// HU 5.1 c2 / 5.2 / 5.4: a report with its reliability, my vote and the
/// option to report it (`/validar/reportes/:id`).
class DetalleReportePage extends StatelessWidget {
  /// HU 5.2 c3.
  static const String textoInsuficiente =
      'Aún no hay información suficiente para determinar la confiabilidad.';

  static const String textoBasadoEnComunidad =
      'Basado en confirmaciones de la comunidad';

  /// S24: the vote breakdown in one compact line, "2 confirman · 1 rechazan".
  static String desglose(Confiabilidad c) =>
      '${c.confirmaciones} confirman · ${c.rechazos} rechazan';

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
          final cargado = state as DetalleCargado;
          final tier = cargado.tierVotante;
          mostrarAviso(
            context,
            cargado.aviso!,
            alLado: tier == null ? null : TierCompacto(tier),
          );
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
    return ListaPerezosa.secciones(
      padding: const EdgeInsets.all(16),
      secciones: [
        // S24: the same card and pieces as the Validar card.
        TarjetaReporte(
          children: [
            EncabezadoReporte(
              lugar: d.lugar.nombre,
              estado: ChipEstadoValidacion(estado: d.estadoValidacion),
              tierAutor: d.tierAutor,
            ),
            const SizedBox(height: 12),
            SeccionSaturacion(nivel: d.nivel),
            const SizedBox(height: 12),
            SeccionConfiabilidad(
              confiabilidad: c,
              detalle: [
                Text(
                  c.nivel == NivelConfiabilidad.insuficiente
                      ? DetalleReportePage.textoInsuficiente
                      : DetalleReportePage.textoBasadoEnComunidad,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                Text(DetalleReportePage.desglose(c)),
                if (c.nivel == NivelConfiabilidad.baja && c.advertencia != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      c.advertencia!,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ),
              ],
            ),
            if (voto != null) ...[
              const SizedBox(height: 16),
              Text(
                voto == TipoAccionValidacion.confirmar
                    ? 'Tu voto: Confirmaste este reporte'
                    : 'Tu voto: Rechazaste este reporte',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ] else if (!d.esPropio) ...[
              const SizedBox(height: 16),
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
            ],
            if (!d.esPropio) ...[
              const SizedBox(height: 12),
              if (d.yaDenunciado)
                const Text(
                  'Ya denunciaste este reporte',
                  style: TextStyle(color: AppColors.textMuted),
                )
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
          ],
        ),
      ],
    );
  }
}
