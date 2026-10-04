import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../core/network/generic_response.dart';

import '../../../core/models/user_model.dart';

import '../../../core/session/session_service.dart';
import '../../../core/session/usuario_sesion.dart';

class UserService {
  Future<GenericResponse<UserModel>> getProfile() async {
    final token = SessionService.instance.token;
    if (token == null) {
      return const GenericResponse<UserModel>(
        success: false,
        message: 'No hay sesión activa',
      );
    }

    final res = await http.get(
      ApiConfig.uri(ApiConfig.profile),
      headers: ApiConfig.authHeaders(token),
    );

    final Map<String, dynamic> body = _decode(res.bodyBytes);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final user = UserModel.fromJson(body['data'] as Map<String, dynamic>? ?? {});
      return GenericResponse<UserModel>(
        success: true,
        data: user,
        message: body['message'] as String? ?? '',
      );
    }

    return GenericResponse<UserModel>(
      success: false,
      message: body['message'] as String? ?? 'Error al obtener el perfil',
    );
  }

  Future<GenericResponse<UserModel>> updateProfile(Map<String, dynamic> cambios) async {
    final token = SessionService.instance.token;
    if (token == null) {
      return const GenericResponse<UserModel>(
        success: false,
        message: 'No hay sesión activa',
      );
    }

    final res = await http.put(
      ApiConfig.uri(ApiConfig.profile),
      headers: ApiConfig.authHeaders(token),
      body: jsonEncode(cambios),
    );

    final Map<String, dynamic> body = _decode(res.bodyBytes);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final user = UserModel.fromJson(body['data'] as Map<String, dynamic>? ?? {});

      await SessionService.instance
          .actualizarUsuario(UsuarioSesion.desdeUserModel(user));

      return GenericResponse<UserModel>(
        success: true,
        data: user,
        message: body['message'] as String? ?? '',
      );
    }

    return GenericResponse<UserModel>(
      success: false,
      message: body['message'] as String? ?? 'Error al actualizar el perfil',
    );
  }

  Map<String, dynamic> _decode(List<int> bodyBytes) {
    try {
      return jsonDecode(utf8.decode(bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
