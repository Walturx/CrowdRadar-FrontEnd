import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/session/sesion_cubit.dart';
import '../features/auth/data/auth_service.dart';
import '../features/auth/login/login_cubit.dart';
import '../features/perfil/data/user_service.dart';
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
  late final GoRouter _router =
      crearRouter(_sesion, ubicacionInicial: widget.ubicacionInicial);

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
        RepositoryProvider<AuthService>.value(value: deps.authService),
        RepositoryProvider<UserService>.value(value: deps.userService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<SesionCubit>.value(value: _sesion),
          BlocProvider(create: (c) => AuthCubit(c.read<AuthService>())),
        ],
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
