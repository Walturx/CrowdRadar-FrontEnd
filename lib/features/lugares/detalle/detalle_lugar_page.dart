import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/map/tipos_mapa.dart';
import '../../../core/models/lugar_detalle.dart';
import '../../../core/models/nivel_saturacion.dart';
import '../../../core/utils/formato_fecha.dart';
import '../../../core/widgets/cargando.dart';
import '../../../core/widgets/chip_saturacion.dart';
import '../../../core/widgets/estado_error.dart';
import '../../../core/widgets/etiqueta_seccion.dart';
import '../../../theme/app_colors.dart';
import '../../favoritos/data/favorito_repository.dart';
import '../categoria_presentacion.dart';
import '../data/lugar_repository.dart';
import 'detalle_lugar_cubit.dart';
import 'detalle_lugar_state.dart';

/// Place detail (`/mapa/lugares/:id`); [centroMapa] is the map centre the user
/// came from, used for the distance (omitted when unknown).
class DetalleLugarPage extends StatelessWidget {
  static const String tituloError = 'Información no disponible';
  static const String mensajeSinInformacion =
      'Aún no hay reportes suficientes para determinar la saturación de este lugar.';

  final int lugarId;
  final PuntoGeografico? centroMapa;

  const DetalleLugarPage({super.key, required this.lugarId, this.centroMapa});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DetalleLugarCubit(
        context.read<LugarRepository>(),
        context.read<FavoritoRepository>(),
        lugarId,
      )..cargar(),
      child: _DetalleView(centroMapa),
    );
  }
}

class _DetalleView extends StatelessWidget {
  final PuntoGeografico? centroMapa;

  const _DetalleView(this.centroMapa);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DetalleLugarCubit, DetalleLugarState>(
      listenWhen: (previo, actual) =>
          actual is DetalleCargado &&
          actual.errorFavorito != null &&
          (previo is! DetalleCargado ||
              previo.errorFavorito != actual.errorFavorito),
      listener: (context, state) {
        final error = (state as DetalleCargado).errorFavorito!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      },
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: Text(
            state is DetalleCargado
                ? state.detalle.nombre
                : 'Detalle del lugar',
          ),
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
          DetalleCargado() => _Contenido(state.detalle, centroMapa),
        },
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  final LugarDetalle detalle;
  final PuntoGeografico? centroMapa;

  const _Contenido(this.detalle, this.centroMapa);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Text(
              emojiCategoria(detalle.categoria),
              style: const TextStyle(fontSize: 36),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detalle.nombre,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtituloLugar(
                      detalle.categoria,
                      detalle.latitud,
                      detalle.longitud,
                      centroMapa,
                    ),
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const EtiquetaSeccion('SATURACIÓN AHORA'),
        _BloqueSaturacion(detalle.saturacion),
        const EtiquetaSeccion('INFORMACIÓN'),
        if (detalle.direccion != null) _Fila('Dirección', detalle.direccion!),
        if (detalle.horarioAtencion != null)
          _Fila('Horario', detalle.horarioAtencion!),
      ],
    );
  }
}

class _BloqueSaturacion extends StatelessWidget {
  final SaturacionLugar saturacion;

  const _BloqueSaturacion(this.saturacion);

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
    final sinInformacion = saturacion.nivel == NivelSaturacion.sinInformacion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: ChipSaturacion(nivel: saturacion.nivel),
        ),
        const SizedBox(height: 6),
        Text(
          sinInformacion
              ? (saturacion.mensaje ?? DetalleLugarPage.mensajeSinInformacion)
              : _actualizacion,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _Fila(this.etiqueta, this.valor);

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}
