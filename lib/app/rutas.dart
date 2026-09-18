/// Frozen route table: the only place route path literals live.
class Rutas {
  Rutas._();

  // Public
  static const String login = '/login';
  static const String registro = '/registro';
  static const String recuperar = '/recuperar';
  static const List<String> publicas = [login, registro, recuperar];

  // Main shell
  static const String mapa = '/mapa';
  static const String explorar = '/mapa/explorar';
  static const String buscarLugar = '/mapa/buscar';
  static const String lugarPlantilla = '/mapa/lugares/:id';
  static const String historialPlantilla = '$lugarPlantilla/historial';
  static const String compararPlantilla = '$lugarPlantilla/comparar';
  static const String mejorHorarioPlantilla = '$lugarPlantilla/mejor-horario';
  static String lugar(int id) => _con(lugarPlantilla, id);
  static String historial(int id) => _con(historialPlantilla, id);
  static String comparar(int id) => _con(compararPlantilla, id);
  static String mejorHorario(int id) => _con(mejorHorarioPlantilla, id);
  static const String validar = '/validar';
  static const String reporteValidarPlantilla = '/validar/reportes/:id';
  static String reporteValidar(int id) => _con(reporteValidarPlantilla, id);
  static const String favoritos = '/favoritos';
  static const String alertas = '/favoritos/alertas';
  static const String perfil = '/perfil';
  static const String perfilEditar = '/perfil/editar';
  static const String perfilPassword = '/perfil/password';
  static const String perfilAcerca = '/perfil/acerca';
  static const String perfilReportes = '/perfil/reportes';
  static const String perfilValidaciones = '/perfil/validaciones';

  // Admin shell
  static const String admin = '/admin';
  static const String adminReportes = '/admin/reportes';
  static const String adminReportePlantilla = '/admin/reportes/:id';
  static String adminReporte(int id) => _con(adminReportePlantilla, id);
  static const String adminUsuarios = '/admin/usuarios';
  static const String adminUsuarioPlantilla = '/admin/usuarios/:id';
  static String adminUsuario(int id) => _con(adminUsuarioPlantilla, id);

  static String _con(String plantilla, int id) =>
      plantilla.replaceFirst(':id', '$id');

  /// Segment of [completa] below [padre], as nested `GoRoute`s expect.
  static String relativa(String completa, String padre) =>
      completa.substring(padre.length + 1);
}
