import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/reporte_saturacion.dart';
import '../../../core/utils/formato_fecha.dart';
import '../../../core/widgets/cargando.dart';
import '../../../core/widgets/chip_saturacion.dart';
import '../../../core/widgets/estado_error.dart';
import '../../../core/widgets/lista_perezosa.dart';
import '../../../theme/app_colors.dart';
import '../../../core/models/validacion.dart';
import '../../validacion/data/validacion_repository.dart';
import '../../validacion/estado/estado_validacion_cubit.dart';
import '../../validacion/estado/estado_validacion_state.dart';
import '../../validacion/widgets/chip_estado_validacion.dart';
import '../data/reporte_repository.dart';
import 'mis_reportes_cubit.dart';
import 'mis_reportes_state.dart';

/// HU 4.3: the user's own report history, newest first, paginated.
class MisReportesPage extends StatelessWidget {
  static const String mensajeVacioTitulo = 'Aún no tienes reportes';
  static const String mensajeVacio =
      'Cuando reportes la saturación de un lugar, aparecerá aquí tu historial.';

  final int tamanoPagina;

  /// When given, each row shows its validation status (M5 chip).
  final ValidacionRepository? validacion;

  const MisReportesPage({super.key, this.tamanoPagina = 20, this.validacion});

  @override
  Widget build(BuildContext context) {
    final repositorioValidacion = validacion;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => MisReportesCubit(
            context.read<ReporteRepository>(),
            size: tamanoPagina,
          )..cargar(),
        ),
        if (repositorioValidacion != null)
          BlocProvider(
            create: (_) =>
                EstadoValidacionCubit(repositorioValidacion)..cargar(),
          ),
      ],
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
            MisReportesCargado() => _Lista(
              state,
              conEstados: repositorioValidacion != null,
            ),
          },
        ),
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  final MisReportesCargado estado;

  /// The validation statuses are available in the context (M5).
  final bool conEstados;

  const _Lista(this.estado, {this.conEstados = false});

  @override
  Widget build(BuildContext context) {
    final estados = conEstados
        ? context.watch<EstadoValidacionCubit>().state
        : null;
    final reportes = estado.reportes;
    return ListaPerezosa(
      padding: const EdgeInsets.only(bottom: 24),
      cantidad: reportes.length,
      idFila: (i) => reportes[i].id,
      fila: (context, i) => _Fila(
        reportes[i],
        validacion: estados is EstadoValidacionCargado
            ? estados.estadoDe(reportes[i].id)
            : null,
      ),
      pie: [
        for (final error in [estado.errorActualizacion, estado.errorMas])
          if (error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                error,
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
  final EstadoValidacion? validacion;

  const _Fila(this.reporte, {this.validacion});

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
          if (validacion != null) ChipEstadoValidacion(estado: validacion!),
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
