import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../core/map/tipos_mapa.dart';
import '../core/models/usuario.dart';
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
import '../features/lugares/buscar/buscar_lugar_page.dart';
import '../features/lugares/detalle/detalle_lugar_page.dart';
import '../features/moderacion/reportes_denunciados/reportes_denunciados_page.dart';
import '../features/moderacion/revision_reporte/revision_reporte_page.dart';
import '../features/moderacion/usuario_detalle/usuario_admin_detalle_page.dart';
import '../features/moderacion/usuarios/usuarios_admin_page.dart';
import '../features/perfil/acerca/acerca_page.dart';
import '../features/perfil/cambiar_password/cambiar_password_page.dart';
import '../features/reportes/mis_reportes/mis_reportes_page.dart';
import '../core/map/centro_compartido.dart';
import '../features/validacion/detalle_reporte/detalle_reporte_page.dart';
import '../features/validacion/estado/estado_validacion_page.dart';
import '../features/validacion/pendientes/validar_page.dart';
import '../layout/admin_layout.dart';
import '../layout/main_layout.dart';
import 'guards.dart';
import 'rutas.dart';

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

String _hija(String completa, String padre) => Rutas.relativa(completa, padre);

/// Path parameter `:id` as an int (0 when absent or malformed).
int _id(GoRouterState state) =>
    int.tryParse(state.pathParameters['id'] ?? '') ?? 0;

/// Map centre passed as `extra` by the screens that open a place or the search.
PuntoGeografico? _centroDe(GoRouterState state) =>
    state.extra is PuntoGeografico ? state.extra as PuntoGeografico : null;

GoRoute _pagina(
  String path,
  Widget Function(GoRouterState state) pagina, {
  List<RouteBase> routes = const [],
}) =>
    GoRoute(path: path, builder: (_, state) => pagina(state), routes: routes);

GoRouter crearRouter(SesionCubit sesion, {String ubicacionInicial = Rutas.mapa}) {
  // The map writes its centre here and the validation tab reads it.
  final centroMapa = CentroMapaCompartido();
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
              builder: (_, _) => MapPage(centroCompartido: centroMapa),
              routes: [
                _pagina(_hija(Rutas.explorar, Rutas.mapa), (_) => const ExplorarPage()),
                _pagina(
                  _hija(Rutas.buscarLugar, Rutas.mapa),
                  (s) => BuscarLugarPage(centroMapa: _centroDe(s)),
                ),
                _pagina(
                  _hija(Rutas.lugarPlantilla, Rutas.mapa),
                  (s) => DetalleLugarPage(
                    lugarId: _id(s),
                    centroMapa: _centroDe(s),
                  ),
                  routes: [
                    _pagina(_hija(Rutas.historialPlantilla, Rutas.lugarPlantilla), (s) => HistorialPage(lugarId: _id(s))),
                    _pagina(_hija(Rutas.compararPlantilla, Rutas.lugarPlantilla), (s) => CompararPage(lugarId: _id(s))),
                    _pagina(
                      _hija(Rutas.mejorHorarioPlantilla, Rutas.lugarPlantilla),
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
              builder: (_, _) => ValidarPage(centro: centroMapa),
              routes: [
                _pagina(
                  _hija(Rutas.reporteValidarPlantilla, Rutas.validar),
                  (s) => DetalleReportePage(reporteId: _id(s)),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Rutas.favoritos,
              builder: (_, _) => const FavoritosPage(),
              routes: [_pagina(_hija(Rutas.alertas, Rutas.favoritos), (_) => const AlertasPage())],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Rutas.perfil,
              builder: (_, _) => const ProfilePage(),
              routes: [
                GoRoute(
                  path: _hija(Rutas.perfilEditar, Rutas.perfil),
                  builder: (_, state) {
                    final extra = state.extra as Map<String, dynamic>?;
                    return EditProfilePage(
                      user: extra != null ? Usuario.fromJson(extra) : null,
                    );
                  },
                ),
                _pagina(_hija(Rutas.perfilPassword, Rutas.perfil), (_) => const CambiarPasswordPage()),
                _pagina(_hija(Rutas.perfilAcerca, Rutas.perfil), (_) => const AcercaPage()),
                _pagina(_hija(Rutas.perfilReportes, Rutas.perfil), (_) => const MisReportesPage()),
                _pagina(_hija(Rutas.perfilValidaciones, Rutas.perfil), (_) => const EstadoValidacionPage()),
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
                _pagina(_hija(Rutas.adminReportePlantilla, Rutas.adminReportes), (s) => RevisionReportePage(reporteId: _id(s))),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            _pagina(
              Rutas.adminUsuarios,
              (_) => const UsuariosAdminPage(),
              routes: [
                _pagina(
                  _hija(Rutas.adminUsuarioPlantilla, Rutas.adminUsuarios),
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
