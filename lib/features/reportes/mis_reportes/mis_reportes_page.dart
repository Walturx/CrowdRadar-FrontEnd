import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/reporte_saturacion.dart';
import '../../../core/utils/formato_fecha.dart';
import '../../../core/widgets/cargando.dart';
import '../../../core/widgets/chip_saturacion.dart';
import '../../../core/widgets/estado_error.dart';
import '../../../theme/app_colors.dart';
import '../data/reporte_repository.dart';
import 'mis_reportes_cubit.dart';
import 'mis_reportes_state.dart';

/// HU 4.3: the user's own report history, newest first, paginated.
class MisReportesPage extends StatelessWidget {
  static const String mensajeVacioTitulo = 'Aún no tienes reportes';
  static const String mensajeVacio =
      'Cuando reportes la saturación de un lugar, aparecerá aquí tu historial.';

  final int tamanoPagina;

  const MisReportesPage({super.key, this.tamanoPagina = 20});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MisReportesCubit(
        context.read<ReporteRepository>(),
        size: tamanoPagina,
      )..cargar(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Mis reportes')),
        body: BlocBuilder<MisReportesCubit, MisReportesState>(
          builder: (context, state) => switch (state) {
            MisReportesCargando() => const Cargando(),
            MisReportesVacio() => const EstadoError(
              titulo: mensajeVacioTitulo,
              mensaje: mensajeVacio,
            ),
            MisReportesError() => EstadoError(
              mensaje: state.mensaje,
              onReintentar: () => context.read<MisReportesCubit>().cargar(),
            ),
            MisReportesCargado() => _Lista(state),
          },
        ),
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  final MisReportesCargado estado;

  const _Lista(this.estado);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final r in estado.reportes) _Fila(r),
        if (estado.errorMas != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              estado.errorMas!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        if (estado.cargandoMas)
          const Padding(padding: EdgeInsets.all(12), child: Cargando())
        else if (estado.hayMas)
          Center(
            child: TextButton(
              onPressed: () => context.read<MisReportesCubit>().cargarMas(),
              child: const Text('Cargar más'),
            ),
          ),
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  static const Map<String, String> _motivos = {
    'TOPE_DIARIO': 'Tope diario alcanzado',
    'REPORTE_ELIMINADO': 'Reporte eliminado',
  };

  final ReporteSaturacion reporte;

  const _Fila(this.reporte);

  @override
  Widget build(BuildContext context) {
    final puntos = reporte.puntosOtorgados;
    final motivo = reporte.motivoSinPuntos;
    final fecha = reporte.fechaHora;
    return ListTile(
      title: Text(reporte.lugarNombre ?? 'Lugar ${reporte.lugarId}'),
      subtitle: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ChipSaturacion(nivel: reporte.nivel),
          if (fecha != null) Text(haceCuanto(fecha)),
          if (puntos == 0 && motivo != null)
            Text(
              _motivos[motivo] ?? motivo,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
        ],
      ),
      trailing: puntos == null
          ? null
          : Text(
              '+$puntos',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
    );
  }
}
