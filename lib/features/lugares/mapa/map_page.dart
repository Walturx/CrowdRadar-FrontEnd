import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/rutas.dart';
import '../../../core/map/mapa_adapter.dart';
import '../../../core/map/centro_compartido.dart';
import '../../../core/map/tipos_mapa.dart';
import '../../../core/widgets/tarjeta_error.dart';
import '../../../core/widgets/estado_vacio.dart';
import '../../../theme/app_colors.dart';
import '../../exploracion/explorar/filtros_mapa.dart';
import '../data/lugar_repository.dart';
import 'leyenda_saturacion.dart';
import 'mapa_cubit.dart';
import 'mapa_state.dart';
import 'marcadores.dart';

class MapPage extends StatelessWidget {
  /// Where the camera centre is published for the other tabs.
  final CentroMapaCompartido? centroCompartido;

  const MapPage({super.key, this.centroCompartido});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MapaCubit(context.read<LugarRepository>()),
      child: _MapView(centroCompartido),
    );
  }
}

class _MapView extends StatefulWidget {
  final CentroMapaCompartido? centroCompartido;

  const _MapView(this.centroCompartido);

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  static const PuntoGeografico _centroLima = PuntoGeografico(
    -12.0464,
    -77.0428,
  );
  static const String _tituloError = 'No pudimos cargar el mapa';

  /// The offline banner is shown once per outage: tiles fail in bursts.
  bool _avisoMostrado = false;
  bool _avisoVisible = false;
  bool _errorDescartado = false;

  void _alCamaraQuieta(LimitesMapa limites) {
    widget.centroCompartido?.actualizar(limites);
    final cubit = context.read<MapaCubit>();
    // The first report loads at once; later ones wait for the camera to settle.
    if (!cubit.yaCargo) {
      cubit.cargar(limites);
    } else {
      cubit.alMoverCamara(limites);
    }
  }

  /// Opens the search route, which pops the chosen place id; that place opens
  /// its detail from the current map centre.
  Future<void> _abrirBusqueda() async {
    final cubit = context.read<MapaCubit>();
    final id = await context.push<int>(Rutas.buscarLugar, extra: cubit.centro);
    if (id != null && mounted) {
      context.push(Rutas.lugar(id), extra: cubit.centro);
    }
  }

  void _alErrorTile() {
    if (_avisoMostrado || !mounted) return;
    setState(() {
      _avisoMostrado = true;
      _avisoVisible = true;
    });
  }

  /// Tiles load again: the outage is over, so the banner may return in the next one.
  void _alTileCargado() {
    if (!_avisoMostrado || !mounted) return;
    setState(() {
      _avisoMostrado = false;
      _avisoVisible = false;
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
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Tu zona',
                      style: TextStyle(
                        color: AppColors.onPrimaryMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Lima, Perú',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _CampoBusqueda(onTap: _abrirBusqueda),
                  ],
                ),
              ),
            ),
          ),
          FiltrosMapa(
            alCambiar: (categoria, nivel) =>
                cubit.aplicarFiltros(categoria: categoria, nivel: nivel),
          ),
          Expanded(
            child: BlocConsumer<MapaCubit, MapaState>(
              listenWhen: (_, actual) => actual is! MapaError,
              listener: (_, _) {
                if (_errorDescartado) setState(() => _errorDescartado = false);
              },
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
                      eventos: EventosMapa(
                        alMoverCamara: cubit.alMoverCamara,
                        alCamaraQuieta: _alCamaraQuieta,
                        alErrorTile: _alErrorTile,
                        alTileCargado: _alTileCargado,
                      ),
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
                  if (state is MapaError && !_errorDescartado)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: TarjetaError(
                        titulo: _tituloError,
                        mensaje: state.mensaje,
                        onReintentar: cubit.reintentar,
                        onCerrar: () => setState(() => _errorDescartado = true),
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

class _CampoBusqueda extends StatelessWidget {
  final VoidCallback onTap;

  const _CampoBusqueda({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.search, color: AppColors.textMuted),
              SizedBox(width: 8),
              Text(
                'Buscar lugares',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
