import 'entorno.dart';

class ApiConfig {
  static final String baseUrl = Entorno.desdeDartDefine().apiUrl;

  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String profile = '/api/users/profile';

  static Uri uri(String path) => Uri.parse('$baseUrl$path');

  static const Map<String, String> jsonHeaders = {
    'Content-Type': 'application/json',
  };

  static Map<String, String> authHeaders(String token) => {
    ...jsonHeaders,
    'Authorization': 'Bearer $token',
  };
}
