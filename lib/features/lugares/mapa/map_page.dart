import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/rutas.dart';
import '../../../core/map/mapa_adapter.dart';
import '../../../core/map/tipos_mapa.dart';
import '../../../core/widgets/estado_error.dart';
import '../../../core/widgets/estado_vacio.dart';
import '../../../theme/app_colors.dart';
import '../data/lugar_repository.dart';
import 'leyenda_saturacion.dart';
import 'mapa_cubit.dart';
import 'mapa_state.dart';
import 'marcadores.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MapaCubit(context.read<LugarRepository>()),
      child: const _MapView(),
    );
  }
}

class _MapView extends StatefulWidget {
  const _MapView();

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  static const PuntoGeografico _centroLima = PuntoGeografico(
    -12.0464,
    -77.0428,
  );
  static const String _tituloError = 'No pudimos cargar el mapa';

  /// The offline banner is shown once per session: tiles fail in bursts.
  bool _avisoMostrado = false;
  bool _avisoVisible = false;

  void _alCamaraQuieta(LimitesMapa limites) {
    final cubit = context.read<MapaCubit>();
    // The first report loads at once; later ones wait for the camera to settle.
    if (cubit.centro == null) {
      cubit.cargar(limites);
    } else {
      cubit.alMoverCamara(limites);
    }
  }

  void _alErrorTile() {
    if (_avisoMostrado || !mounted) return;
    setState(() {
      _avisoMostrado = true;
      _avisoVisible = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MapaCubit>();
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.primary,
            child: const SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tu zona',
                      style: TextStyle(
                        color: AppColors.onPrimaryMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Lima, Perú',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<MapaCubit, MapaState>(
              builder: (context, state) => Stack(
                children: [
                  Positioned.fill(
                    child: context.read<MapaAdapter>().construirMapa(
                      centro: _centroLima,
                      zoom: 12,
                      marcadores: marcadoresDe(switch (state) {
                        MapaCargado() => state.lugares,
                        MapaCargando() => state.lugares,
                        MapaError() => const [],
                      }),
                      alTocarMarcador: (id) =>
                          context.push(Rutas.lugar(id), extra: cubit.centro),
                      alCamaraQuieta: _alCamaraQuieta,
                      alErrorTile: _alErrorTile,
                    ),
                  ),
                  if (state is MapaCargando)
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(),
                    ),
                  if (state is MapaCargado && state.mensajeVacio != null)
                    Align(
                      alignment: Alignment.center,
                      child: IgnorePointer(
                        child: Container(
                          margin: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              EstadoVacio(
                                icon: Icons.map_outlined,
                                title: 'Sin lugares',
                                subtitle: state.mensajeVacio!,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (state is MapaError)
                    Positioned.fill(
                      child: ColoredBox(
                        color: AppColors.surface,
                        child: EstadoError(
                          titulo: _tituloError,
                          mensaje: state.mensaje,
                          onReintentar: cubit.reintentar,
                        ),
                      ),
                    ),
                  if (_avisoVisible)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: _AvisoSinConexion(
                        onCerrar: () => setState(() => _avisoVisible = false),
                      ),
                    ),
                  const Positioned(
                    left: 12,
                    bottom: 12,
                    child: LeyendaSaturacion(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvisoSinConexion extends StatelessWidget {
  final VoidCallback onCerrar;

  const _AvisoSinConexion({required this.onCerrar});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warning,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(Icons.wifi_off, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Sin conexión al mapa',
                style: TextStyle(color: Colors.white),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: Colors.white),
              onPressed: onCerrar,
            ),
          ],
        ),
      ),
    );
  }
}
