import '../../../core/widgets/lista_perezosa.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/rutas.dart';
import '../../../core/location/punto_referencia.dart';
import '../../../core/models/validacion.dart';
import '../../../core/utils/distancia.dart';
import '../../../core/utils/formato_fecha.dart';
import '../../../core/widgets/cargando.dart';
import '../../../core/widgets/estado_error.dart';
import '../../../core/widgets/estado_vacio.dart';
import '../../../core/widgets/mostrar_aviso.dart';
import '../../../theme/app_colors.dart';
import '../../lugares/categoria_presentacion.dart';
import '../data/validacion_repository.dart';
import '../widgets/tarjeta_reporte.dart';
import '../widgets/tier_compacto.dart';
import 'pendientes_cubit.dart';
import 'pendientes_state.dart';

/// HU 5.1: vote on the reports other users made near the user (the device
/// location, or the map centre when it is not available: CRO-65).
class ValidarPage extends StatelessWidget {
  static const String tituloVacio = 'No hay reportes por validar';
  static const String mensajeVacio =
      'Cuando otros usuarios reporten cerca de ti, aparecerán aquí.';
  static const String mensajeVacioCentroMapa =
      'Cuando otros usuarios reporten cerca del centro del mapa, aparecerán '
      'aquí.';
  static const String avisoCentroMapa =
      'No pudimos usar tu ubicación: buscamos reportes cerca del centro del '
      'mapa.';

  final PuntoReferencia referencia;

  const ValidarPage({super.key, required this.referencia});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          PendientesCubit(context.read<ValidacionRepository>(), referencia)
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
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
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
    final enCentroMapa = estado.origen == OrigenReferencia.centroMapa;
    return ListaPerezosa.secciones(
      padding: const EdgeInsets.all(16),
      secciones: [
        if (enCentroMapa) const _AvisoCentroMapa(),
        if (voto != null) _Gracias(voto),
        if (siguiente == null)
          SizedBox(
            height: 360,
            child: EstadoVacio(
              icon: Icons.shield_outlined,
              title: ValidarPage.tituloVacio,
              subtitle: enCentroMapa
                  ? ValidarPage.mensajeVacioCentroMapa
                  : ValidarPage.mensajeVacio,
            ),
          )
        else
          _TarjetaPendiente(siguiente, restantes: estado.reportes.length - 1),
      ],
    );
  }
}

/// CRO-65: the reports are not around the user, so the page says where.
class _AvisoCentroMapa extends StatelessWidget {
  const _AvisoCentroMapa();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(Icons.location_off_outlined, color: AppColors.textMuted),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              ValidarPage.avisoCentroMapa,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

/// HU 5.1 c2: thanks and the choice just made (no points are announced), with
/// the voter's own tier beside the thanks when the response carried it (S23).
class _Gracias extends StatelessWidget {
  final VotoRegistrado voto;

  const _Gracias(this.voto);

  @override
  Widget build(BuildContext context) {
    final eligio = voto.accion == TipoAccionValidacion.confirmar
        ? 'Confirmaste'
        : 'Rechazaste';
    final tier = voto.tier;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              key: const Key('fila-gracias'),
              children: [
                const Expanded(
                  child: Text(
                    '¡Gracias por validar!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                if (tier != null) ...[
                  const SizedBox(width: 8),
                  TierCompacto(tier),
                ],
              ],
            ),
            const Text('Tu aporte mejora la confiabilidad de la información.'),
            const SizedBox(height: 8),
            Text('$eligio el reporte de ${voto.reporte.lugar.nombre}'),
          ],
        ),
      ),
    );
  }
}

/// The next report to vote on, in the shared report card (S24).
class _TarjetaPendiente extends StatelessWidget {
  final ReportePendiente reporte;
  final int restantes;

  const _TarjetaPendiente(this.reporte, {required this.restantes});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PendientesCubit>();
    final distancia = reporte.distanciaMetros;
    final categoria = etiquetaCategoria(reporte.lugar.categoria);
    final fecha = reporte.fechaHora;
    return TarjetaReporte(
      children: [
        EncabezadoReporte(
          antetitulo: 'Ayuda a la comunidad',
          lugar: reporte.lugar.nombre,
          subtitulo: distancia == null
              ? categoria
              : '$categoria · ${formatoDistancia(distancia.toDouble())}',
          estado: fecha == null ? null : PildoraTiempo(haceCuanto(fecha)),
          tierAutor: reporte.tierAutor,
        ),
        const SizedBox(height: 14),
        PreguntaNivel(nivel: reporte.nivel),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SeccionConfiabilidad(confiabilidad: reporte.confiabilidad),
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: () => context.push(Rutas.reporteValidar(reporte.id)),
                child: const Text('Ver detalle de confiabilidad →'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('boton-rechazar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(
                    color: AppColors.dangerBorder,
                    width: 1.5,
                  ),
                ),
                onPressed: () =>
                    cubit.votar(reporte, TipoAccionValidacion.rechazar),
                icon: const Icon(Icons.close, size: 19),
                label: const Text('Rechazar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                key: const Key('boton-confirmar'),
                onPressed: () =>
                    cubit.votar(reporte, TipoAccionValidacion.confirmar),
                icon: const Icon(Icons.check, size: 19),
                label: const Text('Confirmar'),
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
    );
  }
}
