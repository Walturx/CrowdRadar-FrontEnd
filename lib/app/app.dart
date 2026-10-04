import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/logging/registro_errores.dart';
import '../core/map/mapa_adapter.dart';
import '../core/session/motivo_cierre.dart';
import '../core/session/sesion_cubit.dart';
import '../core/session/sesion_state.dart';
import '../core/session/session_service.dart';
import '../features/alertas/data/alerta_repository.dart';
import '../features/analitica/data/analitica_repository.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/exploracion/data/exploracion_repository.dart';
import '../features/favoritos/data/favorito_repository.dart';
import '../features/lugares/data/lugar_repository.dart';
import '../features/moderacion/data/moderacion_repository.dart';
import '../features/perfil/data/perfil_repository.dart';
import '../features/reportes/data/reporte_repository.dart';
import '../features/validacion/data/validacion_repository.dart';
import '../theme/app_theme.dart';
import 'app_router.dart';
import 'dependencias.dart';
import 'registro_dispositivo.dart';
import 'rutas.dart';

class CrowdRadarApp extends StatefulWidget {
  final Dependencias dependencias;
  final String ubicacionInicial;

  const CrowdRadarApp({
    super.key,
    required this.dependencias,
    this.ubicacionInicial = Rutas.mapa,
  });

  @override
  State<CrowdRadarApp> createState() => _CrowdRadarAppState();
}

class _CrowdRadarAppState extends State<CrowdRadarApp> {
  late final RegistroDispositivo _dispositivo = RegistroDispositivo(
    receptor: widget.dependencias.receptorPush,
    alertas: widget.dependencias.alertaRepository,
  );
  late final SesionCubit _sesion = SesionCubit(
    widget.dependencias.sesion,
    antesDeCerrar: _dispositivo.quitar,
  );
  late final GoRouter _router = crearRouter(
    _sesion,
    ubicacionInicial: widget.ubicacionInicial,
  );
  StreamSubscription<EventoSesion>? _eventosSesion;
  StreamSubscription<int>? _toques;

  /// A place tapped in a notification before the session was ready (single
  /// slot: the last tap wins). Delivered on sign in, dropped on sign out.
  int? _toquePendiente;

  @override
  void initState() {
    super.initState();
    final deps = widget.dependencias;
    // Created first so its session listener runs before ours.
    _sesion;
    // Listen before initializing: a tap that launched the app is emitted by
    // `inicializar` itself.
    _toques = deps.receptorPush.lugarAbierto.listen(_abrirLugar);
    unawaited(_iniciarPush());
    // A restored session registers the device now; later sign ins on the event
    // ([RegistroDispositivo] never sends the same token twice).
    if (deps.sesion.token != null) unawaited(_dispositivo.registrar());
    _eventosSesion = deps.sesion.eventos.listen(_alCambiarSesion);
  }

  void _alCambiarSesion(EventoSesion evento) {
    switch (evento) {
      case SesionIniciada():
        unawaited(_dispositivo.registrar());
        final pendiente = _toquePendiente;
        _toquePendiente = null;
        if (pendiente != null) _abrirLugar(pendiente);
      case SesionCerrada(:final motivo):
        _toquePendiente = null;
        // A user sign out already ran the hook while the session was valid;
        // a forced close tries best effort (it is retried on the next sign in).
        if (motivo != MotivoCierre.usuario) unawaited(_dispositivo.quitar());
    }
  }

  Future<void> _iniciarPush() async {
    try {
      await widget.dependencias.receptorPush.inicializar();
    } catch (e, pila) {
      const RegistroErroresConsola().registrar('push.inicializar', e, pila);
    }
  }

  /// A notification tap (also the one that launched the app) opens the place;
  /// without a session it waits for the sign in.
  void _abrirLugar(int lugarId) {
    if (_sesion.state is! SesionAutenticada) {
      _toquePendiente = lugarId;
      return;
    }
    // After the frame, so a tap that launched the app finds the router built.
    WidgetsBinding.instance
      ..addPostFrameCallback((_) {
        if (mounted) _router.push(Rutas.lugar(lugarId));
      })
      ..scheduleFrame();
  }

  @override
  void dispose() {
    _eventosSesion?.cancel();
    _toques?.cancel();
    _router.dispose();
    _sesion.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deps = widget.dependencias;
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: deps.authRepository),
        RepositoryProvider<PerfilRepository>.value(
          value: deps.perfilRepository,
        ),
        RepositoryProvider<MapaAdapter>.value(value: deps.mapaAdapter),
        RepositoryProvider<LugarRepository>.value(value: deps.lugarRepository),
        RepositoryProvider<ReporteRepository>.value(
          value: deps.reporteRepository,
        ),
        RepositoryProvider<AnaliticaRepository>.value(
          value: deps.analiticaRepository,
        ),
        RepositoryProvider<ValidacionRepository>.value(
          value: deps.validacionRepository,
        ),
        RepositoryProvider<FavoritoRepository>.value(
          value: deps.favoritoRepository,
        ),
        RepositoryProvider<AlertaRepository>.value(
          value: deps.alertaRepository,
        ),
        RepositoryProvider<ExploracionRepository>.value(
          value: deps.exploracionRepository,
        ),
        RepositoryProvider<ModeracionRepository>.value(
          value: deps.moderacionRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [BlocProvider<SesionCubit>.value(value: _sesion)],
        child: MaterialApp.router(
          title: 'CrowdRadar',
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          routerConfig: _router,
        ),
      ),
    );
  }
}
