import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/nivel_saturacion.dart';
import '../../../core/widgets/boton_principal.dart';
import '../../../core/widgets/chip_saturacion.dart';
import '../../../core/widgets/medidor_nivel.dart';
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
    // design-system section 5: radius 28 on top over a 45 % ink scrim.
    backgroundColor: AppColors.surface,
    barrierColor: const Color(0x730F172A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
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
  /// Levels a user can report ("Sin información" is not a choice).
  static const List<NivelSaturacion> _niveles = [
    NivelSaturacion.tranquilo,
    NivelSaturacion.moderado,
    NivelSaturacion.saturado,
  ];

  /// D4: the wait between reports lives only on the server, so no number.
  static const String notaReporte =
      'Puedes volver a reportar este lugar más tarde';

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
          10,
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
        const _Asa(),
        const SizedBox(height: 14),
        const Text(
          '¿Qué tan lleno está?',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            height: 1.25,
            color: AppColors.text,
          ),
        ),
        Text(
          lugarNombre,
          style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
        const SizedBox(height: 14),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        for (final nivel in ReportarSheet._niveles)
          _Opcion(
            nivel: nivel,
            seleccionada: state.nivel == nivel,
            onTap: enviando ? null : () => cubit.seleccionarNivel(nivel),
          ),
        const SizedBox(height: 2),
        const Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                ReportarSheet.notaReporte,
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        BotonPrincipal(
          key: const Key('boton-enviar-reporte'),
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

/// Handle of the sheet: 40 x 4 px (design-system section 5).
class _Asa extends StatelessWidget {
  const _Asa();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

/// One level option: a meter tile, the level name and description, and a
/// radio circle. Chosen, its border takes the level `dot` color with a 4 px
/// halo and the circle shows a check.
class _Opcion extends StatelessWidget {
  static const double _radio = 16;

  final NivelSaturacion nivel;
  final bool seleccionada;
  final VoidCallback? onTap;

  const _Opcion({
    required this.nivel,
    required this.seleccionada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dot = ChipSaturacion.colorDe(nivel);
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_radio),
      side: BorderSide(
        color: seleccionada ? dot : AppColors.border,
        width: 1.5,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        key: Key('opcion-nivel-${nivel.name}'),
        container: true,
        selected: seleccionada,
        button: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radio),
            boxShadow: [
              if (seleccionada)
                BoxShadow(color: dot.withValues(alpha: 0.22), spreadRadius: 4),
            ],
          ),
          child: Material(
            color: seleccionada
                ? ChipSaturacion.bgDe(nivel).withValues(alpha: 0.5)
                : AppColors.surface,
            shape: forma,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: ChipSaturacion.bgDe(nivel),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: MedidorNivel(
                        nivel: nivel,
                        color: ChipSaturacion.fgDe(nivel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ChipSaturacion.etiquetaDe(nivel),
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                          ),
                          Text(
                            ChipSaturacion.descripcionDe(nivel),
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _Circulo(seleccionada: seleccionada, color: dot),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Radio circle of an option; chosen, it is filled with a check.
class _Circulo extends StatelessWidget {
  final bool seleccionada;
  final Color color;

  const _Circulo({required this.seleccionada, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 22,
    height: 22,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: seleccionada ? color : null,
      border: seleccionada
          ? null
          : Border.all(color: AppColors.iconMuted, width: 1.5),
    ),
    child: seleccionada
        ? const Icon(
            Icons.check,
            key: ValueKey('check-opcion-nivel'),
            size: 15,
            color: AppColors.surface,
          )
        : null,
  );
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
        const SizedBox(height: 16),
        BotonPrincipal(
          texto: 'Listo',
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
