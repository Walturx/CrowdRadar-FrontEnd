import '../core/session/sesion_state.dart';
import 'rutas.dart';

/// Drops a trailing slash so `/login/` and `/login` are the same route.
String _normalizar(String ruta) =>
    ruta.length > 1 && ruta.endsWith('/')
        ? ruta.substring(0, ruta.length - 1)
        : ruta;

bool _esAdmin(String ruta) =>
    ruta == Rutas.admin || ruta.startsWith('${Rutas.admin}/');

/// Session guard. Returns the redirect target or null to stay.
String? redirigirPorSesion(SesionState sesion, String ubicacion) {
  final ruta = _normalizar(ubicacion);
  final esPublica = Rutas.publicas.contains(ruta);
  return switch (sesion) {
    SesionNoAutenticada() => esPublica ? null : Rutas.login,
    SesionAutenticada(:final esAdmin) when esPublica =>
      esAdmin ? Rutas.adminReportes : Rutas.mapa,
    SesionAutenticada(:final esAdmin) when !esAdmin && _esAdmin(ruta) =>
      Rutas.mapa,
    SesionAutenticada() => null,
  };
}
