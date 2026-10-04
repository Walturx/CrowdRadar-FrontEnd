import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/nivel_saturacion.dart';
import '../../../core/widgets/boton_principal.dart';
import '../../../core/widgets/chip_saturacion.dart';
import '../../../theme/app_colors.dart';
import '../data/reporte_repository.dart';
import 'reportar_cubit.dart';
import 'reportar_state.dart';

/// Opens the report sheet; completes with `true` when a report was sent, however
/// the sheet was dismissed (Listo, swipe or scrim), so the caller can refresh
/// what it shows.
///
/// The [cubit] outlives the sheet when the caller supplies it, so a request still
/// in flight at dismissal is not lost; the caller then closes it. Without one the
/// sheet creates its own and closes it after dismissal.
Future<bool?> mostrarReportarSheet(
  BuildContext context, {
  required int lugarId,
  required String lugarNombre,
  ReportarCubit? cubit,
}) async {
  final propio = cubit == null;
  final reportar =
      cubit ?? ReportarCubit(context.read<ReporteRepository>(), lugarId);
  var enviado = false;
  final resultado = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => ReportarSheet(
      cubit: reportar,
      lugarNombre: lugarNombre,
      onEnviado: () => enviado = true,
    ),
  );
  if (propio) await reportar.close();
  return enviado ? true : resultado;
}

/// HU 4.1: choose Tranquilo / Moderado / Saturado and send the report. It only
/// renders the [cubit]'s state; whoever created the cubit owns and closes it.
class ReportarSheet extends StatelessWidget {
  static const Map<NivelSaturacion, String> _descripciones = {
    NivelSaturacion.tranquilo: 'Hay espacio, poca gente',
    NivelSaturacion.moderado: 'Algo concurrido',
    NivelSaturacion.saturado: 'Lleno, mucha gente',
  };

  final ReportarCubit cubit;
  final String lugarNombre;

  /// Called once the report was accepted.
  final VoidCallback? onEnviado;

  const ReportarSheet({
    super.key,
    required this.cubit,
    required this.lugarNombre,
    this.onEnviado,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: BlocConsumer<ReportarCubit, ReportarState>(
          listenWhen: (_, actual) => actual is ReportarEnviado,
          listener: (_, _) => onEnviado?.call(),
          builder: (context, state) => switch (state) {
            ReportarEnviado() => _Exito(state),
            _ => _Formulario(lugarNombre, state),
          },
        ),
      ),
    );
  }
}

class _Formulario extends StatelessWidget {
  final String lugarNombre;
  final ReportarState state;

  const _Formulario(this.lugarNombre, this.state);

  String? get _error => switch (state) {
    ReportarEditando(:final error) => error,
    ReportarFallido(:final mensaje) => mensaje,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReportarCubit>();
    final enviando = state is ReportarEnviando;
    final fallo = state is ReportarFallido ? state as ReportarFallido : null;
    final bloqueante = fallo?.bloqueante ?? false;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '¿Qué tan lleno está?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        Text(lugarNombre, style: const TextStyle(color: AppColors.textMuted)),
        const SizedBox(height: 12),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        for (final e in ReportarSheet._descripciones.entries)
          _Opcion(
            nivel: e.key,
            descripcion: e.value,
            seleccionada: state.nivel == e.key,
            onTap: enviando ? null : () => cubit.seleccionarNivel(e.key),
          ),
        const SizedBox(height: 8),
        BotonPrincipal(
          texto: (fallo?.reintentable ?? false)
              ? 'Reintentar'
              : 'Enviar reporte',
          cargando: enviando,
          onPressed: bloqueante ? null : cubit.enviar,
        ),
        if (bloqueante)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
      ],
    );
  }
}

class _Opcion extends StatelessWidget {
  final NivelSaturacion nivel;
  final String descripcion;
  final bool seleccionada;
  final VoidCallback? onTap;

  const _Opcion({
    required this.nivel,
    required this.descripcion,
    required this.seleccionada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = ChipSaturacion.colorDe(nivel);
    return Semantics(
      selected: seleccionada,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: seleccionada ? color.withValues(alpha: 0.12) : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: seleccionada ? color : AppColors.border,
              width: seleccionada ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(radius: 6, backgroundColor: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ChipSaturacion.etiquetaDe(nivel),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      descripcion,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Exito extends StatelessWidget {
  final ReportarEnviado estado;

  const _Exito(this.estado);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          estado.mensaje,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tu reporte fue enviado correctamente y ya ayuda a otros ciudadanos.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          '+${estado.puntosGanados} karma',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        if (estado.motivoSinPuntos != null)
          Text(
            estado.motivoSinPuntos!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted),
          ),
        const SizedBox(height: 12),
        BotonPrincipal(
          texto: 'Listo',
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
