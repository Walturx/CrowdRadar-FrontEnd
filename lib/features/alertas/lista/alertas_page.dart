import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/rutas.dart';
import '../../../core/models/alerta.dart';
import '../../../core/utils/formato_fecha.dart';
import '../../../core/widgets/cargando.dart';
import '../../../core/widgets/chip_saturacion.dart';
import '../../../core/widgets/estado_error.dart';
import '../../../core/widgets/estado_vacio.dart';
import '../../../core/widgets/mostrar_aviso.dart';
import '../../../theme/app_colors.dart';
import 'alertas_cubit.dart';
import 'alertas_state.dart';

/// HU 8.3: saturation alerts of the favorites, unread first. Tapping one marks
/// it read and opens the place. The [AlertasCubit] comes from the signed-in
/// shell, which also feeds the badge of the Favoritos tab.
class AlertasPage extends StatefulWidget {
  static const String mensajeVacio = 'No tienes alertas.';
  static const String ayudaVacio =
      'Te avisaremos cuando cambie la saturación de tus favoritos.';

  const AlertasPage({super.key});

  @override
  State<AlertasPage> createState() => _AlertasPageState();
}

class _AlertasPageState extends State<AlertasPage> {
  @override
  void initState() {
    super.initState();
    // Opening the list refreshes it without blanking what is already there.
    final cubit = context.read<AlertasCubit>();
    if (cubit.state is AlertasCargado) cubit.refrescar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alertas')),
      body: BlocConsumer<AlertasCubit, AlertasState>(
        listenWhen: (previo, actual) =>
            actual is AlertasCargado &&
            actual.error != null &&
            (previo is! AlertasCargado || previo.error != actual.error),
        listener: (context, state) =>
            mostrarAviso(context, (state as AlertasCargado).error!),
        builder: (context, state) => switch (state) {
          AlertasCargando() => const Cargando(),
          AlertasError() => EstadoError(
            mensaje: state.mensaje,
            onReintentar: () => context.read<AlertasCubit>().cargar(),
          ),
          AlertasCargado(alertas: final alertas) when alertas.isEmpty =>
            const EstadoVacio(
              icon: Icons.notifications_none,
              title: AlertasPage.mensajeVacio,
              subtitle: AlertasPage.ayudaVacio,
            ),
          AlertasCargado() => ListView(
            padding: const EdgeInsets.all(16),
            children: [for (final a in state.alertas) _Tarjeta(a)],
          ),
        },
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  final Alerta alerta;

  const _Tarjeta(this.alerta);

  @override
  Widget build(BuildContext context) {
    final fecha = alerta.fechaHora;
    final cuando = fecha == null ? '' : ' ${haceCuanto(fecha)}';
    return Card(
      color: alerta.leida ? AppColors.surface : AppColors.bg,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context.read<AlertasCubit>().marcarLeida(alerta.id);
          context.push(Rutas.lugar(alerta.lugarId));
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (!alerta.leida)
                    Container(
                      key: Key('no-leida-${alerta.id}'),
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      '${alerta.lugarNombre} ahora está '
                      '${ChipSaturacion.etiquetaDe(alerta.nivelNuevo)}',
                      style: TextStyle(
                        fontWeight: alerta.leida
                            ? FontWeight.w500
                            : FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'La saturación cambió de '
                '${ChipSaturacion.etiquetaDe(alerta.nivelAnterior)} a '
                '${ChipSaturacion.etiquetaDe(alerta.nivelNuevo)}$cuando.',
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ChipSaturacion(nivel: alerta.nivelAnterior),
                  const Icon(Icons.arrow_forward, size: 16),
                  ChipSaturacion(nivel: alerta.nivelNuevo),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Recibes esta alerta porque ${alerta.lugarNombre} está en tus '
                'favoritos.',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
