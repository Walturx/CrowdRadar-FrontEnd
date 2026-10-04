import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../core/models/user_model.dart';
import '../core/session/sesion_cubit.dart';
import '../core/session/sesion_state.dart';
import '../features/auth/login/login_page.dart';
import '../features/auth/registro/register_page.dart';
import '../features/favoritos/lista/favoritos_page.dart';
import '../features/lugares/mapa/map_page.dart';
import '../features/perfil/editar/edit_profile_page.dart';
import '../features/perfil/ver/profile_page.dart';
import '../features/alertas/lista/alertas_page.dart';
import '../features/analitica/comparar/comparar_page.dart';
import '../features/analitica/historial/historial_page.dart';
import '../features/analitica/mejor_horario/mejor_horario_page.dart';
import '../features/auth/recuperar/recuperar_page.dart';
import '../features/exploracion/explorar/explorar_page.dart';
import '../features/lugares/detalle/detalle_lugar_page.dart';
import '../features/moderacion/reportes_denunciados/reportes_denunciados_page.dart';
import '../features/moderacion/revision_reporte/revision_reporte_page.dart';
import '../features/moderacion/usuario_detalle/usuario_admin_detalle_page.dart';
import '../features/moderacion/usuarios/usuarios_admin_page.dart';
import '../features/perfil/cambiar_password/cambiar_password_page.dart';
import '../features/reportes/mis_reportes/mis_reportes_page.dart';
import '../features/validacion/detalle_reporte/detalle_reporte_page.dart';
import '../features/validacion/estado/estado_validacion_page.dart';
import '../features/validacion/pendientes/validar_page.dart';
import '../layout/admin_layout.dart';
import '../layout/main_layout.dart';
import 'rutas.dart';

/// Session guard. Returns the redirect target or null to stay.
String? redirigirPorSesion(SesionState sesion, String ubicacion) {
  final esPublica = Rutas.publicas.contains(ubicacion);
  return switch (sesion) {
    SesionNoAutenticada() => esPublica ? null : Rutas.login,
    SesionAutenticada(:final esAdmin) when esPublica =>
      esAdmin ? Rutas.adminReportes : Rutas.mapa,
    SesionAutenticada(:final esAdmin)
        when !esAdmin && ubicacion.startsWith(Rutas.admin) =>
      Rutas.mapa,
    SesionAutenticada() => null,
  };
}

/// Re-evaluates router redirects on every session change.
class _RefrescoPorSesion extends ChangeNotifier {
  late final StreamSubscription<SesionState> _suscripcion;

  _RefrescoPorSesion(Stream<SesionState> estados) {
    _suscripcion = estados.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _suscripcion.cancel();
    super.dispose();
  }
}

/// Path parameter `:id` as an int (0 when absent or malformed).
int _id(GoRouterState state) =>
    int.tryParse(state.pathParameters['id'] ?? '') ?? 0;

GoRoute _pagina(
  String path,
  Widget Function(GoRouterState state) pagina, {
  List<RouteBase> routes = const [],
}) =>
    GoRoute(path: path, builder: (_, state) => pagina(state), routes: routes);

GoRouter crearRouter(SesionCubit sesion, {String ubicacionInicial = Rutas.mapa}) {
  return GoRouter(
    initialLocation: ubicacionInicial,
    refreshListenable: _RefrescoPorSesion(sesion.stream),
    redirect: (context, state) =>
        redirigirPorSesion(sesion.state, state.uri.path),
    routes: [
      GoRoute(path: Rutas.login, builder: (_, _) => const LoginPage()),
      GoRoute(path: Rutas.registro, builder: (_, _) => const RegisterPage()),
      _pagina(Rutas.recuperar, (_) => const RecuperarPage()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainLayout(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: Rutas.mapa,
              builder: (_, _) => const MapPage(),
              routes: [
                _pagina('explorar', (_) => const ExplorarPage()),
                _pagina(
                  'lugares/:id',
                  (s) => DetalleLugarPage(lugarId: _id(s)),
                  routes: [
                    _pagina('historial', (s) => HistorialPage(lugarId: _id(s))),
                    _pagina('comparar', (s) => CompararPage(lugarId: _id(s))),
                    _pagina(
                      'mejor-horario',
                      (s) => MejorHorarioPage(lugarId: _id(s)),
                    ),
                  ],
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Rutas.validar,
              builder: (_, _) => const ValidarPage(),
              routes: [
                _pagina(
                  'reportes/:id',
                  (s) => DetalleReportePage(reporteId: _id(s)),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Rutas.favoritos,
              builder: (_, _) => const FavoritosPage(),
              routes: [_pagina('alertas', (_) => const AlertasPage())],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Rutas.perfil,
              builder: (_, _) => const ProfilePage(),
              routes: [
                GoRoute(
                  path: 'editar',
                  builder: (_, state) {
                    final extra = state.extra as Map<String, dynamic>?;
                    return EditProfilePage(
                      user: extra != null ? UserModel.fromJson(extra) : null,
                    );
                  },
                ),
                _pagina('password', (_) => const CambiarPasswordPage()),
                _pagina('reportes', (_) => const MisReportesPage()),
                _pagina('validaciones', (_) => const EstadoValidacionPage()),
              ],
            ),
          ]),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AdminLayout(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            _pagina(
              Rutas.adminReportes,
              (_) => const ReportesDenunciadosPage(),
              routes: [
                _pagina(':id', (s) => RevisionReportePage(reporteId: _id(s))),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            _pagina(
              Rutas.adminUsuarios,
              (_) => const UsuariosAdminPage(),
              routes: [
                _pagina(
                  ':id',
                  (s) => UsuarioAdminDetallePage(usuarioId: _id(s)),
                ),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
}
