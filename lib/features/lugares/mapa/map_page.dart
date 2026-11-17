import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/rutas.dart';
import '../../../core/location/punto_referencia.dart';
import '../../../core/map/mapa_adapter.dart';
import '../../../core/map/centro_compartido.dart';
import '../../../core/map/tipos_mapa.dart';
import '../../../core/widgets/tarjeta_error.dart';
import '../../../core/widgets/estado_vacio.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_shadows.dart';
import '../../exploracion/explorar/filtros_mapa.dart';
import '../data/lugar_repository.dart';
import 'leyenda_saturacion.dart';
import 'mapa_cubit.dart';
import 'mapa_state.dart';
import 'marcadores.dart';

class MapPage extends StatelessWidget {
  /// Where the camera centre is published for the other tabs.
  final CentroMapaCompartido? centroCompartido;

  /// Point the search and place detail measure distances from (CRO-65).
  final PuntoReferencia? referencia;

  const MapPage({super.key, this.centroCompartido, this.referencia});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MapaCubit(context.read<LugarRepository>()),
      child: _MapView(centroCompartido, referencia),
    );
  }
}

class _MapView extends StatefulWidget {
  final CentroMapaCompartido? centroCompartido;
  final PuntoReferencia? referencia;

  const _MapView(this.centroCompartido, this.referencia);

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  static const String _tituloError = 'No pudimos cargar el mapa';

  /// The offline banner is shown once per outage: tiles fail in bursts.
  bool _avisoMostrado = false;
  bool _avisoVisible = false;
  bool _errorDescartado = false;

  @override
  void initState() {
    super.initState();
    // The map is the first screen: ask for the location (and its permission)
    // now, so the first search or detail already measures from the device.
    final referencia = widget.referencia;
    if (referencia != null) unawaited(referencia.actualizar());
  }

  /// The device location when known, else the live camera centre.
  PuntoGeografico? _origenDistancia(MapaCubit cubit) =>
      widget.referencia?.dispositivo ?? cubit.centro;

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
  /// its detail. Both measure from the same [_origenDistancia], read once: a
  /// location that arrives meanwhile must not make them disagree.
  Future<void> _abrirBusqueda() async {
    final origen = _origenDistancia(context.read<MapaCubit>());
    final id = await context.push<int>(Rutas.buscarLugar, extra: origen);
    if (id != null && mounted) {
      context.push(Rutas.lugar(id), extra: origen);
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
      // Full-screen map; the search, the filters and the banner float on top.
      body: Stack(
        children: [
          Positioned.fill(
            child: BlocConsumer<MapaCubit, MapaState>(
              listenWhen: (_, actual) => actual is! MapaError,
              listener: (_, _) {
                if (_errorDescartado) setState(() => _errorDescartado = false);
              },
              builder: (context, state) => Stack(
                children: [
                  Positioned.fill(
                    child: context.read<MapaAdapter>().construirMapa(
                      centro: CentroMapaCompartido.lima,
                      zoom: 12,
                      marcadores: marcadoresDe(switch (state) {
                        MapaCargado() => state.lugares,
                        MapaCargando() => state.lugares,
                        MapaError() => const [],
                      }),
                      alTocarMarcador: (id) => context.push(
                        Rutas.lugar(id),
                        extra: _origenDistancia(cubit),
                      ),
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
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: AppShadows.floating,
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
                  // Under the error card, which covers it while shown.
                  const Positioned(
                    left: 16,
                    bottom: 16,
                    child: LeyendaSaturacion(),
                  ),
                  if (state is MapaError && !_errorDescartado)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: TarjetaError(
                        titulo: _tituloError,
                        mensaje: state.mensaje,
                        onReintentar: cubit.reintentar,
                        onCerrar: () => setState(() => _errorDescartado = true),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: _CampoBusqueda(onTap: _abrirBusqueda),
                  ),
                  FiltrosMapa(
                    alCambiar: (categoria, nivel) => cubit.aplicarFiltros(
                      categoria: categoria,
                      nivel: nivel,
                    ),
                  ),
                  if (_avisoVisible)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: _AvisoSinConexion(
                        onCerrar: () => setState(() => _avisoVisible = false),
                      ),
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
      color: AppColors.text,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.only(left: 14),
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
              key: const ValueKey('cerrar-aviso-mapa'),
              icon: const Icon(Icons.close, size: 18, color: Colors.white),
              onPressed: onCerrar,
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating search pill (design-system sections 4 and 5): 48 px high,
/// white, with `shadow-2`. It opens the search screen.
class _CampoBusqueda extends StatelessWidget {
  static const double _alto = 48;

  final VoidCallback onTap;

  const _CampoBusqueda({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const forma = StadiumBorder();
    return DecoratedBox(
      decoration: const ShapeDecoration(
        shape: forma,
        shadows: AppShadows.floating,
      ),
      child: Material(
        key: const ValueKey('buscador-mapa'),
        color: AppColors.surface,
        shape: forma,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: const SizedBox(
            height: _alto,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.search, color: AppColors.textMuted, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Buscar lugares',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 15.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
