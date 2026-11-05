import '../core/session/sesion_state.dart';
import 'rutas.dart';

/// Drops a trailing slash so `/login/` and `/login` are the same route.
String _normalizar(String ruta) => ruta.length > 1 && ruta.endsWith('/')
    ? ruta.substring(0, ruta.length - 1)
    : ruta;

bool _esRutaAdmin(String ruta) =>
    ruta == Rutas.admin || ruta.startsWith('${Rutas.admin}/');

/// Where each role lands: an ADMIN moderates, a USUARIO uses the map.
String _inicioDe({required bool esAdmin}) =>
    esAdmin ? Rutas.adminReportes : Rutas.mapa;

/// Session guard. Returns the redirect target or null to stay.
///
/// A signed-in user on a public route, or on the other role's area, goes to
/// their own home. That covers the login, a restored session (the app starts
/// on /mapa) and deep links.
String? redirigirPorSesion(SesionState sesion, String ubicacion) {
  final ruta = _normalizar(ubicacion);
  final esPublica = Rutas.publicas.contains(ruta);
  return switch (sesion) {
    SesionNoAutenticada() => esPublica ? null : Rutas.login,
    SesionAutenticada(:final esAdmin)
        when esPublica || esAdmin != _esRutaAdmin(ruta) =>
      _inicioDe(esAdmin: esAdmin),
    SesionAutenticada() => null,
  };
}
