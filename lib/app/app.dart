import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/map/mapa_adapter.dart';
import '../core/session/sesion_cubit.dart';
import '../features/analitica/data/analitica_repository.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/favoritos/data/favorito_repository.dart';
import '../features/lugares/data/lugar_repository.dart';
import '../features/moderacion/data/moderacion_repository.dart';
import '../features/perfil/data/perfil_repository.dart';
import '../features/reportes/data/reporte_repository.dart';
import '../features/validacion/data/validacion_repository.dart';
import '../theme/app_theme.dart';
import 'app_router.dart';
import 'dependencias.dart';
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
  late final SesionCubit _sesion = SesionCubit(widget.dependencias.sesion);
  late final GoRouter _router = crearRouter(
    _sesion,
    ubicacionInicial: widget.ubicacionInicial,
  );

  @override
  void dispose() {
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
