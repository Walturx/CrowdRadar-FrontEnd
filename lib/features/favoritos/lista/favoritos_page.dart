import '../../../core/widgets/lista_perezosa.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/rutas.dart';
import '../../../core/models/favorito.dart';
import '../../../core/widgets/cargando.dart';
import '../../../core/widgets/chip_saturacion.dart';
import '../../../core/widgets/confirmar_accion.dart';
import '../../../core/widgets/estado_error.dart';
import '../../../core/widgets/estado_vacio.dart';
import '../../../core/widgets/etiqueta_seccion.dart';
import '../../../core/widgets/mostrar_aviso.dart';
import '../../../theme/app_colors.dart';
import '../../lugares/categoria_presentacion.dart';
import '../data/favorito_repository.dart';
import 'favoritos_cubit.dart';
import 'favoritos_state.dart';

/// HU 8.2 / 8.3 / 8.4: saved places with their level, alert preferences and
/// removal behind a confirmation.
class FavoritosPage extends StatelessWidget {
  static const String mensajeEliminado =
      'Se eliminó el lugar de tus favoritos.';
  static const String tituloVacio = 'Sin favoritos aún';
  static const String subtituloVacio =
      'Marca lugares con el corazón para seguir su saturación de un vistazo.';

  const FavoritosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          FavoritosCubit(context.read<FavoritoRepository>())..cargar(),
      child: const _FavoritosView(),
    );
  }
}

class _FavoritosView extends StatefulWidget {
  const _FavoritosView();

  @override
  State<_FavoritosView> createState() => _FavoritosViewState();
}

class _FavoritosViewState extends State<_FavoritosView> {
  bool? _activa;

  /// Refreshes (keeping the list on screen) when the tab becomes active again,
  /// so a place marked or unmarked elsewhere shows up.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final activa = TickerMode.valuesOf(context).enabled;
    if (_activa == false && activa) context.read<FavoritosCubit>().refrescar();
    _activa = activa;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoritos'),
        actions: [
          IconButton(
            key: const Key('ir-alertas'),
            tooltip: 'Alertas',
            icon: const Icon(Icons.notifications_none),
            onPressed: () => context.push(Rutas.alertas),
          ),
        ],
      ),
      body: BlocConsumer<FavoritosCubit, FavoritosState>(
        listenWhen: (previo, actual) =>
            actual is FavoritosCargado &&
            ((actual.eliminado != null &&
                    (previo is! FavoritosCargado ||
                        previo.eliminado != actual.eliminado)) ||
                (actual.error != null &&
                    (previo is! FavoritosCargado ||
                        previo.error != actual.error))),
        listener: _avisar,
        builder: (context, state) => switch (state) {
          FavoritosCargando() => const Cargando(),
          FavoritosError() => EstadoError(
            mensaje: state.mensaje,
            onReintentar: () => context.read<FavoritosCubit>().cargar(),
          ),
          FavoritosCargado() => _Lista(state),
        },
      ),
    );
  }

  void _avisar(BuildContext context, FavoritosState state) {
    final cargado = state as FavoritosCargado;
    if (cargado.error != null) {
      mostrarAviso(context, cargado.error!);
      return;
    }
    // The toast can outlive the page: hold the cubit, not the context.
    final cubit = context.read<FavoritosCubit>();
    mostrarAviso(
      context,
      FavoritosPage.mensajeEliminado,
      etiquetaAccion: 'Deshacer',
      alAccionar: () {
        if (!cubit.isClosed) cubit.deshacerEliminar();
      },
    );
  }
}

class _Lista extends StatelessWidget {
  final FavoritosCargado estado;

  const _Lista(this.estado);

  @override
  Widget build(BuildContext context) {
    final favoritos = estado.favoritos;
    return ListaPerezosa(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      cabecera: [
        _AlertasMaestro(estado),
        EtiquetaSeccion(_conteo(favoritos.length)),
        if (favoritos.isEmpty) const _Vacio(),
      ],
      cantidad: favoritos.length,
      fila: (_, i) {
        final f = favoritos[i];
        return _Fila(f, ocupado: estado.procesando.contains(f.lugarId));
      },
    );
  }

  static String _conteo(int n) => switch (n) {
    0 => 'SIN FAVORITOS',
    1 => '1 LUGAR GUARDADO',
    _ => '$n LUGARES GUARDADOS',
  };
}

class _AlertasMaestro extends StatelessWidget {
  final FavoritosCargado estado;

  const _AlertasMaestro(this.estado);

  @override
  Widget build(BuildContext context) {
    final libre = estado.favoritos.isNotEmpty && estado.procesando.isEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alertas de cambios',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Avísame cuando cambie la saturación',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Switch(
            value: estado.todasConAlertas,
            onChanged: libre
                ? (_) =>
                      context.read<FavoritosCubit>().alternarTodasLasAlertas()
                : null,
          ),
        ],
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const EstadoVacio(
          icon: Icons.favorite_border,
          title: FavoritosPage.tituloVacio,
          subtitle: FavoritosPage.subtituloVacio,
        ),
        ElevatedButton(
          onPressed: () => context.go(Rutas.mapa),
          child: const Text('Explorar el mapa'),
        ),
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  final Favorito favorito;
  final bool ocupado;

  const _Fila(this.favorito, {required this.ocupado});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FavoritosCubit>();
    final id = favorito.lugarId;
    return InkWell(
      onTap: () => context.push(Rutas.lugar(id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Text(
              emojiCategoria(favorito.categoria),
              style: const TextStyle(fontSize: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    favorito.nombre,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    etiquetaCategoria(favorito.categoria),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ChipSaturacion(nivel: favorito.saturacion),
                ],
              ),
            ),
            IconButton(
              key: Key('alertas-$id'),
              tooltip: favorito.alertasActivadas
                  ? 'Desactivar alertas'
                  : 'Activar alertas',
              icon: Icon(
                favorito.alertasActivadas
                    ? Icons.notifications_active
                    : Icons.notifications_off_outlined,
                color: favorito.alertasActivadas
                    ? AppColors.secondary
                    : AppColors.textMuted,
              ),
              onPressed: ocupado ? null : () => cubit.alternarAlertas(id),
            ),
            IconButton(
              key: Key('eliminar-$id'),
              tooltip: 'Quitar de favoritos',
              icon: const Icon(Icons.favorite, color: AppColors.danger),
              onPressed: ocupado ? null : () => _confirmar(context, cubit),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmar(BuildContext context, FavoritosCubit cubit) async {
    final confirmado = await confirmarAccion(
      context,
      titulo: '¿Eliminar de favoritos?',
      contenido: 'Dejarás de recibir alertas de ${favorito.nombre}.',
      etiquetaConfirmar: 'Eliminar',
    );
    if (confirmado) await cubit.eliminar(favorito.lugarId);
  }
}
