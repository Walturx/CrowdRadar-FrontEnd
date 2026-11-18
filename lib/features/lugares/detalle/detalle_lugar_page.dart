import '../../../core/widgets/lista_perezosa.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/rutas.dart';
import '../../../core/map/tipos_mapa.dart';
import '../../../core/models/lugar_detalle.dart';
import '../../../core/models/nivel_saturacion.dart';
import '../../../core/utils/formato_fecha.dart';
import '../../../core/widgets/cargando.dart';
import '../../../core/widgets/chip_saturacion.dart';
import '../../../core/widgets/estado_error.dart';
import '../../../core/widgets/etiqueta_seccion.dart';
import '../../../core/widgets/medidor_nivel.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_shadows.dart';
import '../../favoritos/data/favorito_repository.dart';
import '../../reportes/data/reporte_repository.dart';
import '../../reportes/reportar/reportar_cubit.dart';
import '../../reportes/reportar/reportar_sheet.dart';
import '../../reportes/reportar/reportar_state.dart';
import '../categoria_presentacion.dart';
import '../data/lugar_repository.dart';
import 'detalle_lugar_cubit.dart';
import 'detalle_lugar_state.dart';

/// Place detail (`/mapa/lugares/:id`); [origenDistancia] is the point the
/// distance is measured from: the device location, else the map centre the
/// user came from (omitted when unknown).
class DetalleLugarPage extends StatelessWidget {
  static const String tituloError = 'Información no disponible';
  static const String mensajeSinInformacion =
      'Aún no hay reportes suficientes para determinar la saturación de este lugar.';

  final int lugarId;
  final PuntoGeografico? origenDistancia;

  const DetalleLugarPage({
    super.key,
    required this.lugarId,
    this.origenDistancia,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DetalleLugarCubit(
        context.read<LugarRepository>(),
        context.read<FavoritoRepository>(),
        lugarId,
      )..cargar(),
      child: _DetalleView(origenDistancia),
    );
  }
}

class _DetalleView extends StatelessWidget {
  final PuntoGeografico? origenDistancia;

  const _DetalleView(this.origenDistancia);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DetalleLugarCubit, DetalleLugarState>(
      listenWhen: (previo, actual) =>
          actual is DetalleCargado &&
          actual.aviso != null &&
          (previo is! DetalleCargado || previo.aviso != actual.aviso),
      listener: (context, state) {
        final aviso = (state as DetalleCargado).aviso!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            key: const ValueKey('aviso-detalle-lugar'),
            content: Text(aviso),
          ),
        );
      },
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          // Once loaded, the name heads the content instead (design-system).
          title: state is DetalleCargado
              ? null
              : const Text('Detalle del lugar'),
          actions: [
            if (state is DetalleCargado)
              IconButton(
                tooltip: state.esFavorito
                    ? 'Quitar de favoritos'
                    : 'Agregar a favoritos',
                icon: Icon(
                  state.esFavorito ? Icons.favorite : Icons.favorite_border,
                ),
                onPressed: state.procesandoFavorito
                    ? null
                    : context.read<DetalleLugarCubit>().alternarFavorito,
              ),
          ],
        ),
        body: switch (state) {
          DetalleCargando() => const Cargando(),
          DetalleError() => EstadoError(
            titulo: DetalleLugarPage.tituloError,
            mensaje: state.mensaje,
            onReintentar: state.esNoEncontrado
                ? null
                : context.read<DetalleLugarCubit>().cargar,
          ),
          DetalleCargado() => _Contenido(
            state.detalle,
            origenDistancia,
            onReportar: () => _reportar(context, state.detalle),
            onRefrescar: context.read<DetalleLugarCubit>().refrescar,
          ),
        },
      ),
    );
  }

  /// Opens the report sheet; a sent report refreshes the shown saturation
  /// without blanking the detail. The report cubit lives here, not in the
  /// sheet, so a request still in flight when the sheet is dismissed is not
  /// lost: once it succeeds the detail refreshes and the user is thanked.
  Future<void> _reportar(BuildContext context, LugarDetalle detalle) async {
    final detalleCubit = context.read<DetalleLugarCubit>();
    final mensajes = ScaffoldMessenger.of(context);
    final reportar = ReportarCubit(
      context.read<ReporteRepository>(),
      detalle.id,
    );
    try {
      final enviado = await mostrarReportarSheet(
        context,
        lugarId: detalle.id,
        lugarNombre: detalle.nombre,
        cubit: reportar,
      );
      if (enviado == true) {
        await detalleCubit.refrescar();
        return;
      }
      if (reportar.state is! ReportarEnviando) return;
      final fin = await reportar.stream.firstWhere(
        (e) => e is! ReportarEnviando,
      );
      if (fin is! ReportarEnviado) return;
      mensajes.showSnackBar(
        const SnackBar(
          key: ValueKey('aviso-reporte-enviado'),
          content: Text('Reporte enviado'),
        ),
      );
      await detalleCubit.refrescar();
    } finally {
      await reportar.close();
    }
  }
}

class _Contenido extends StatelessWidget {
  final LugarDetalle detalle;
  final PuntoGeografico? origenDistancia;
  final VoidCallback onReportar;

  /// Pull to refresh: the detail stays on screen until the new one arrives.
  final Future<void> Function() onRefrescar;

  const _Contenido(
    this.detalle,
    this.origenDistancia, {
    required this.onReportar,
    required this.onRefrescar,
  });

  @override
  Widget build(BuildContext context) {
    final filas = [
      if (detalle.direccion != null)
        _Fila(Icons.place_outlined, 'Dirección', detalle.direccion!),
      if (detalle.horarioAtencion != null)
        _Fila(Icons.schedule, 'Horario', detalle.horarioAtencion!),
    ];
    return RefreshIndicator(
      onRefresh: onRefrescar,
      child: ListaPerezosa.secciones(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        // A detail shorter than the screen must still accept the pull gesture.
        physics: const AlwaysScrollableScrollPhysics(),
        secciones: [
          _Encabezado(detalle, origenDistancia),
          const SizedBox(height: 16),
          _TarjetaNivel(detalle.saturacion),
          const SizedBox(height: 16),
          // The one primary action of the screen (design-system section 1).
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppShadows.primaryButton,
            ),
            child: ElevatedButton.icon(
              key: const ValueKey('boton-reportar-saturacion'),
              onPressed: onReportar,
              icon: const Icon(Icons.campaign_outlined, size: 19),
              label: const Text('Reportar saturación'),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            key: const ValueKey('boton-ver-historial'),
            onPressed: () => context.push(Rutas.historial(detalle.id)),
            icon: const Icon(Icons.bar_chart, size: 19),
            label: const Text('Ver historial'),
          ),
          const EtiquetaSeccion('INFORMACIÓN'),
          if (filas.isNotEmpty) _GrupoFilas(filas),
        ],
      ),
    );
  }
}

/// Brand shadow of the filled primary button (design-system section 4).
/// `shadow-1` of the design system (section 4): cards.
/// 36 px icon on a `brand-50` box with radius 11 (design-system section 5).
class _CajaIcono extends StatelessWidget {
  final Widget icono;

  const _CajaIcono(this.icono, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 36,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(11),
    ),
    child: IconTheme.merge(
      data: const IconThemeData(size: 18, color: AppColors.primary),
      child: icono,
    ),
  );
}

/// Category icon, name (24/800) and "categoría · distancia".
class _Encabezado extends StatelessWidget {
  final LugarDetalle detalle;
  final PuntoGeografico? origenDistancia;

  const _Encabezado(this.detalle, this.origenDistancia);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CajaIcono(
          key: const ValueKey('caja-icono-categoria-detalle'),
          Icon(
            iconoCategoria(detalle.categoria),
            key: const ValueKey('icono-categoria-detalle'),
            size: 20,
            semanticLabel: etiquetaCategoria(detalle.categoria),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detalle.nombre,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.48,
                  height: 1.2,
                  color: AppColors.text,
                ),
              ),
              Text(
                subtituloLugar(
                  detalle.categoria,
                  detalle.latitud,
                  detalle.longitud,
                  origenDistancia,
                ),
                style: const TextStyle(
                  fontSize: 14.5,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The big level card (design-system section 7): the level comes first, with
/// its meter, its description, how fresh it is and how many reports back it.
class _TarjetaNivel extends StatelessWidget {
  final SaturacionLugar saturacion;

  const _TarjetaNivel(this.saturacion);

  String get _actualizacion {
    final n = saturacion.reportesRecientes;
    final reportes = '$n ${n == 1 ? "reporte" : "reportes"}';
    final fecha = saturacion.actualizadoEn;
    return fecha == null
        ? reportes
        : 'Actualizado ${haceCuanto(fecha)} · $reportes';
  }

  @override
  Widget build(BuildContext context) {
    final nivel = saturacion.nivel;
    final sinInformacion = nivel == NivelSaturacion.sinInformacion;
    final fg = ChipSaturacion.fgDe(nivel);
    return Container(
      key: const ValueKey('tarjeta-nivel'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ChipSaturacion.bgDe(nivel),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SATURACIÓN AHORA',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.72,
              color: fg,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MedidorNivel(nivel: nivel, color: fg, escala: 34 / 14),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  ChipSaturacion.etiquetaDe(nivel),
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.02,
                    height: 1.0,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            sinInformacion
                ? (saturacion.mensaje ?? DetalleLugarPage.mensajeSinInformacion)
                : ChipSaturacion.descripcionDe(nivel),
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w500,
              color: fg,
            ),
          ),
          if (!sinInformacion) ...[
            const SizedBox(height: 14),
            Divider(height: 1, color: fg.withValues(alpha: 0.15)),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: fg),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _actualizacion,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: fg,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// White card holding the information rows, separated by hairlines.
class _GrupoFilas extends StatelessWidget {
  final List<_Fila> filas;

  const _GrupoFilas(this.filas);

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
      boxShadow: AppShadows.card,
    ),
    child: Column(
      children: [
        for (var i = 0; i < filas.length; i++) ...[
          if (i > 0)
            const Divider(height: 1, indent: 62, color: AppColors.border),
          filas[i],
        ],
      ],
    ),
  );
}

class _Fila extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;

  const _Fila(this.icono, this.etiqueta, this.valor);

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 56),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          _CajaIcono(Icon(icono)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
