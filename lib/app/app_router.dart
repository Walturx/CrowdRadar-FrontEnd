import 'dart:async';

import 'package:flutter/foundation.dart';
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
import '../features/validacion/pendientes/validar_page.dart';
import '../layout/admin_layout.dart';
import '../layout/main_layout.dart';
import 'pagina_provisional.dart';
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

GoRoute _provisional(String path, {List<RouteBase> routes = const []}) =>
    GoRoute(
      path: path,
      builder: (context, state) => const PaginaProvisional(),
      routes: routes,
    );

GoRouter crearRouter(SesionCubit sesion, {String ubicacionInicial = Rutas.mapa}) {
  return GoRouter(
    initialLocation: ubicacionInicial,
    refreshListenable: _RefrescoPorSesion(sesion.stream),
    redirect: (context, state) =>
        redirigirPorSesion(sesion.state, state.uri.path),
    routes: [
      GoRoute(path: Rutas.login, builder: (_, _) => const LoginPage()),
      GoRoute(path: Rutas.registro, builder: (_, _) => const RegisterPage()),
      _provisional(Rutas.recuperar),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainLayout(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: Rutas.mapa,
              builder: (_, _) => const MapPage(),
              routes: [
                _provisional('explorar'),
                _provisional('lugares/:id', routes: [
                  _provisional('historial'),
                  _provisional('comparar'),
                  _provisional('mejor-horario'),
                ]),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Rutas.validar,
              builder: (_, _) => const ValidarPage(),
              routes: [_provisional('reportes/:id')],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Rutas.favoritos,
              builder: (_, _) => const FavoritosPage(),
              routes: [_provisional('alertas')],
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
                _provisional('password'),
                _provisional('reportes'),
                _provisional('validaciones'),
              ],
            ),
          ]),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AdminLayout(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            _provisional(Rutas.adminReportes, routes: [_provisional(':id')]),
          ]),
          StatefulShellBranch(routes: [
            _provisional(Rutas.adminUsuarios, routes: [_provisional(':id')]),
          ]),
        ],
      ),
    ],
  );
}
