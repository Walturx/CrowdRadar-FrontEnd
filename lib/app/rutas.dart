/// Frozen route table.
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
  static String lugar(int id) => '/mapa/lugares/$id';
  static String historial(int id) => '${lugar(id)}/historial';
  static String comparar(int id) => '${lugar(id)}/comparar';
  static String mejorHorario(int id) => '${lugar(id)}/mejor-horario';
  static const String validar = '/validar';
  static String reporteValidar(int id) => '/validar/reportes/$id';
  static const String favoritos = '/favoritos';
  static const String alertas = '/favoritos/alertas';
  static const String perfil = '/perfil';
  static const String perfilEditar = '/perfil/editar';
  static const String perfilPassword = '/perfil/password';
  static const String perfilReportes = '/perfil/reportes';
  static const String perfilValidaciones = '/perfil/validaciones';

  // Admin shell
  static const String admin = '/admin';
  static const String adminReportes = '/admin/reportes';
  static String adminReporte(int id) => '/admin/reportes/$id';
  static const String adminUsuarios = '/admin/usuarios';
  static String adminUsuario(int id) => '/admin/usuarios/$id';
}
