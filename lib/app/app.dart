import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/logging/registro_errores.dart';
import '../core/map/mapa_adapter.dart';
import '../core/push/receptor_push.dart';
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
  late final SesionCubit _sesion;
  late final GoRouter _router = crearRouter(
    _sesion,
    centroMapa: widget.dependencias.centroMapa,
    referencia: widget.dependencias.puntoReferencia,
    ubicacionInicial: widget.ubicacionInicial,
  );

  /// Shows the session-ended notice above the router, so it survives the
  /// redirect to the login, and the notice of a push received in the
  /// foreground.
  final _mensajero = GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<EventoSesion>? _eventosSesion;
  StreamSubscription<int>? _toques;
  StreamSubscription<MensajePrimerPlano>? _mensajesPrimerPlano;

  /// A place tapped in a notification before the session was ready (single
  /// slot: the last tap wins). Delivered on sign in, dropped on sign out.
  int? _toquePendiente;

  @override
  void initState() {
    super.initState();
    final deps = widget.dependencias;
    // Created first so its session listener runs before ours.
    _sesion = SesionCubit(deps.sesion, antesDeCerrar: _dispositivo.quitar);
    // Listen before initializing: a tap that launched the app is emitted by
    // `inicializar` itself.
    _toques = deps.receptorPush.lugarAbierto.listen(_abrirLugar);
    _mensajesPrimerPlano = deps.receptorPush.mensajesEnPrimerPlano.listen(
      _avisarMensaje,
    );
    _eventosSesion = deps.sesion.eventos.listen(_alCambiarSesion);
    // Not needed for the first frame: push setup and the device registration
    // of a restored session (later sign ins register on the event;
    // [RegistroDispositivo] never sends the same token twice) wait for it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_iniciarPush());
      if (deps.sesion.token != null) unawaited(_dispositivo.registrar());
    });
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
        final aviso = switch (motivo) {
          MotivoCierre.sesionExpirada => 'Tu sesión terminó',
          MotivoCierre.cuentaSuspendida => 'Tu cuenta fue suspendida',
          _ => null,
        };
        if (aviso != null) {
          _mensajero.currentState
            ?..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(aviso)));
        }
        // A user or password-change close already ran the hook while the
        // session was valid; a forced close tries best effort (it is retried
        // on the next sign in).
        if (motivo == MotivoCierre.sesionExpirada ||
            motivo == MotivoCierre.cuentaSuspendida) {
          unawaited(_dispositivo.quitar());
        }
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

  /// A push received in the foreground (no system notification): shows its
  /// texts with a "Ver" action that opens its place, when it has one. The
  /// alert inbox reloads on its own (`MainLayout`). Ignored without a session.
  void _avisarMensaje(MensajePrimerPlano mensaje) {
    if (_sesion.state is! SesionAutenticada) return;
    final titulo = mensaje.titulo;
    final cuerpo = mensaje.cuerpo;
    final lugarId = mensaje.lugarId;
    _mensajero.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (titulo != null)
                Text(
                  titulo,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              if (cuerpo != null) Text(cuerpo),
              if (titulo == null && cuerpo == null)
                const Text('Tienes una nueva alerta'),
            ],
          ),
          // It hides on its own even with the action: a notice that stays
          // until dismissed would cover the screen the user is on.
          persist: false,
          duration: const Duration(seconds: 6),
          action: lugarId == null
              ? null
              : SnackBarAction(
                  label: 'Ver',
                  onPressed: () => _abrirLugar(lugarId),
                ),
        ),
      );
  }

  @override
  void dispose() {
    _eventosSesion?.cancel();
    _toques?.cancel();
    _mensajesPrimerPlano?.cancel();
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
        RepositoryProvider<ReceptorPush>.value(value: deps.receptorPush),
      ],
      child: MultiBlocProvider(
        providers: [BlocProvider<SesionCubit>.value(value: _sesion)],
        child: MaterialApp.router(
          title: 'CrowdRadar',
          scaffoldMessengerKey: _mensajero,
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          // Framework texts (back tooltip, field counters, tabs, pickers and
          // dialogs) are read by TalkBack, so they must be Spanish too.
          locale: const Locale('es', 'PE'),
          supportedLocales: const [Locale('es', 'PE')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          routerConfig: _router,
        ),
      ),
    );
  }
}
