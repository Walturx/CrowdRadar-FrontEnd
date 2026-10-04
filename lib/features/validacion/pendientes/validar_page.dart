import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/rutas.dart';
import '../../../core/map/centro_compartido.dart';
import '../../../core/models/validacion.dart';
import '../../../core/utils/distancia.dart';
import '../../../core/widgets/cargando.dart';
import '../../../core/widgets/chip_saturacion.dart';
import '../../../core/widgets/estado_error.dart';
import '../../../core/widgets/estado_vacio.dart';
import '../../../core/widgets/mostrar_aviso.dart';
import '../../../theme/app_colors.dart';
import '../data/validacion_repository.dart';
import '../widgets/insignia_confiabilidad.dart';
import 'pendientes_cubit.dart';
import 'pendientes_state.dart';

/// HU 5.1: vote on the reports other users made near the map centre.
class ValidarPage extends StatelessWidget {
  static const String tituloVacio = 'No hay reportes por validar';
  static const String mensajeVacio =
      'Cuando otros usuarios reporten cerca de ti, aparecerán aquí.';

  final CentroMapaCompartido centro;

  const ValidarPage({super.key, required this.centro});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          PendientesCubit(context.read<ValidacionRepository>(), centro)
            ..cargar(),
      child: BlocConsumer<PendientesCubit, PendientesState>(
        listenWhen: (a, b) => b is PendientesCargado && b.aviso != null,
        listener: (context, state) {
          mostrarAviso(context, (state as PendientesCargado).aviso!);
          context.read<PendientesCubit>().descartarAviso();
        },
        builder: (context, state) => Scaffold(
          appBar: AppBar(
            title: const Text('Validar reportes'),
            actions: [
              IconButton(
                tooltip: 'Actualizar',
                icon: const Icon(Icons.refresh),
                onPressed: () => context.read<PendientesCubit>().cargar(),
              ),
            ],
          ),
          body: switch (state) {
            PendientesCargando() => const Cargando(),
            PendientesError() => EstadoError(
              mensaje: state.mensaje,
              onReintentar: () => context.read<PendientesCubit>().cargar(),
            ),
            PendientesCargado() => _Contenido(state),
          },
        ),
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  final PendientesCargado estado;

  const _Contenido(this.estado);

  @override
  Widget build(BuildContext context) {
    final voto = estado.ultimoVoto;
    final siguiente = estado.reportes.firstOrNull;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (voto != null) _Gracias(voto),
        if (siguiente == null)
          const SizedBox(
            height: 360,
            child: EstadoVacio(
              icon: Icons.shield_outlined,
              title: ValidarPage.tituloVacio,
              subtitle: ValidarPage.mensajeVacio,
            ),
          )
        else
          _TarjetaReporte(siguiente, restantes: estado.reportes.length - 1),
      ],
    );
  }
}

/// HU 5.1 c2: thanks, karma earned and the choice just made.
class _Gracias extends StatelessWidget {
  final VotoRegistrado voto;

  const _Gracias(this.voto);

  @override
  Widget build(BuildContext context) {
    final eligio = voto.accion == TipoAccionValidacion.confirmar
        ? 'Confirmaste'
        : 'Rechazaste';
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¡Gracias por validar!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const Text('Tu aporte mejora la confiabilidad de la información.'),
            const SizedBox(height: 8),
            if (voto.puntosGanados > 0)
              Text(
                '+${voto.puntosGanados} karma',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.success,
                ),
              )
            else
              const Text(
                'Voto registrado (alcanzaste el máximo de karma por hoy)',
              ),
            Text('$eligio el reporte de ${voto.reporte.lugar.nombre}'),
          ],
        ),
      ),
    );
  }
}

class _TarjetaReporte extends StatelessWidget {
  final ReportePendiente reporte;
  final int restantes;

  const _TarjetaReporte(this.reporte, {required this.restantes});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PendientesCubit>();
    final distancia = reporte.distanciaMetros;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ayuda a la comunidad'),
            const SizedBox(height: 8),
            Text(
              reporte.lugar.nombre,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            if (distancia != null) Text(formatoDistancia(distancia.toDouble())),
            const SizedBox(height: 12),
            const Text('Saturación reportada'),
            ChipSaturacion(nivel: reporte.nivel),
            const SizedBox(height: 12),
            const Text('Confiabilidad del reporte'),
            InsigniaConfiabilidad(confiabilidad: reporte.confiabilidad),
            TextButton(
              onPressed: () => context.push(Rutas.reporteValidar(reporte.id)),
              child: const Text('Ver detalle de confiabilidad →'),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        cubit.votar(reporte, TipoAccionValidacion.rechazar),
                    child: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        cubit.votar(reporte, TipoAccionValidacion.confirmar),
                    child: const Text('Confirmar'),
                  ),
                ),
              ],
            ),
            if (restantes > 0)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  restantes == 1
                      ? '1 reporte más por validar'
                      : '$restantes reportes más por validar',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
