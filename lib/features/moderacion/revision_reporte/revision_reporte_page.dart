import '../../../core/widgets/lista_perezosa.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/moderacion.dart';
import '../../../core/utils/formato_fecha.dart';
import '../../../core/widgets/cargando.dart';
import '../../../core/widgets/chip_saturacion.dart';
import '../../../core/widgets/confirmar_accion.dart';
import '../../../core/widgets/estado_error.dart';
import '../../../core/widgets/etiqueta_seccion.dart';
import '../../../core/widgets/mostrar_aviso.dart';
import '../../../theme/app_colors.dart';
import '../data/moderacion_repository.dart';
import '../widgets/etiqueta_motivo.dart';
import 'revision_reporte_cubit.dart';
import 'revision_reporte_state.dart';

/// HU 7.1 c2 / c3: review one reported report and decide (`/admin/reportes/:id`).
///
/// Pops with `true` once the report left the queue (resolved or gone).
class RevisionReportePage extends StatelessWidget {
  final int reporteId;

  const RevisionReportePage({super.key, required this.reporteId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          RevisionReporteCubit(context.read<ModeracionRepository>(), reporteId)
            ..cargar(),
      child: BlocConsumer<RevisionReporteCubit, RevisionReporteState>(
        listenWhen: (a, b) => b is RevisionReporteCargado && b.aviso != null,
        listener: (context, state) {
          mostrarAviso(context, (state as RevisionReporteCargado).aviso!);
          context.read<RevisionReporteCubit>().descartarAviso();
        },
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Reporte denunciado')),
          body: switch (state) {
            RevisionReporteCargando() => const Cargando(),
            RevisionReporteError() => EstadoError(
              mensaje: state.mensaje,
              onReintentar: () => context.read<RevisionReporteCubit>().cargar(),
            ),
            RevisionReporteObsoleta() => _Cierre(
              icono: Icons.info_outline,
              titulo: state.mensaje,
            ),
            RevisionReporteResuelta() => _Cierre(
              icono: Icons.check_circle_outline,
              titulo: state.resolucion.estado == EstadoReporteModerado.eliminado
                  ? 'Reporte eliminado'
                  : 'Reporte mantenido',
              detalle: [
                _resueltas(state.resolucion.denunciasResueltas),
                state.resolucion.estado == EstadoReporteModerado.eliminado
                    ? 'Estado del reporte: Eliminado'
                    : 'Estado del reporte: Activo',
              ],
            ),
            RevisionReporteCargado() => _Detalle(state),
          },
        ),
      ),
    );
  }

  static String _resueltas(int n) =>
      n == 1 ? '1 denuncia resuelta' : '$n denuncias resueltas';
}

class _Detalle extends StatefulWidget {
  final RevisionReporteCargado estado;

  const _Detalle(this.estado);

  @override
  State<_Detalle> createState() => _DetalleState();
}

class _DetalleState extends State<_Detalle> {
  final _comentario = TextEditingController();

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  Future<void> _decidir(DecisionModeracion decision) async {
    final cubit = context.read<RevisionReporteCubit>();
    if (decision == DecisionModeracion.eliminar) {
      final confirmado = await confirmarAccion(
        context,
        titulo: 'Eliminar reporte',
        contenido:
            'El reporte dejará de mostrarse y se revocará el karma que dio.',
        etiquetaConfirmar: 'Eliminar',
      );
      if (!confirmado) return;
    }
    await cubit.resolver(decision, comentario: _comentario.text);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.estado.detalle;
    final fecha = d.fechaHora;
    final ocupado = widget.estado.resolviendo;
    return ListaPerezosa.secciones(
      padding: const EdgeInsets.all(16),
      secciones: [
        Text(
          d.lugar.nombre,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        Text(
          fecha == null
              ? 'Reportado por ${d.autor.nombreCorto}'
              : 'Reportado por ${d.autor.nombreCorto} · ${haceCuanto(fecha)}',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        if (d.autor.email != null) Text(d.autor.email!),
        const SizedBox(height: 12),
        Row(
          children: [
            ChipSaturacion(nivel: d.nivel),
            const SizedBox(width: 8),
            Text(textoDenuncias(d.pendientes)),
          ],
        ),
        const EtiquetaSeccion('MOTIVOS DE LA DENUNCIA'),
        for (final m in d.motivos)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text(etiquetaMotivo(m.motivo)), Text('${m.total}')],
            ),
          ),
        const SizedBox(height: 16),
        TextField(
          controller: _comentario,
          maxLength: RevisionReporteCubit.comentarioMaximo,
          decoration: const InputDecoration(labelText: 'Comentario (opcional)'),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: ocupado
                    ? null
                    : () => _decidir(DecisionModeracion.mantener),
                child: const Text('Mantener'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                ),
                onPressed: ocupado
                    ? null
                    : () => _decidir(DecisionModeracion.eliminar),
                child: const Text('Eliminar reporte'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Closing message of the review (decision recorded, or nothing left to review).
class _Cierre extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final List<String> detalle;

  const _Cierre({
    required this.icono,
    required this.titulo,
    this.detalle = const [],
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 56, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          if (detalle.isNotEmpty) const SizedBox(height: 8),
          for (final linea in detalle) Text(linea, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Volver a la lista'),
          ),
        ],
      ),
    ),
  );
}
