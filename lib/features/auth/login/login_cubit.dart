import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/mensaje_error.dart';
import '../../../core/utils/mensaje_espera.dart';
import '../data/auth_repository.dart';
import 'login_state.dart';

/// Login failure text by backend `code` (HU 1.1 c2/c3); unknown codes keep the
/// API message.
String mensajeDeLogin(Object error) {
  return switch (codigoDeError(error)) {
    'CREDENCIALES_INVALIDAS' => 'Correo o contraseña incorrectos',
    'CUENTA_NO_EXISTE' => 'No existe una cuenta con este correo',
    'CUENTA_SUSPENDIDA' => 'Tu cuenta está suspendida',
    'DEMASIADOS_INTENTOS' ||
    'DEMASIADAS_SOLICITUDES' =>
      mensajeEspera(esperaDeError(error)),
    _ => mensajeDeError(error),
  };
}

class LoginCubit extends Cubit<LoginState> {
  final AuthRepository _repositorio;

  LoginCubit(this._repositorio) : super(const LoginInicial());

  /// A submit while another is in flight is ignored.
  bool _enVuelo = false;

  Future<void> iniciarSesion(String email, String password) async {
    if (_enVuelo) return;
    _enVuelo = true;
    emit(const LoginEnviando());
    try {
      emit(LoginExitoso(await _repositorio.iniciarSesion(email, password)));
    } catch (e) {
      emit(LoginFallido(
        mensajeDeLogin(e),
        codigo: codigoDeError(e),
        esSinConexion: esErrorSinConexion(e),
        reintentarEnSegundos: esperaDeError(e),
      ));
    } finally {
      _enVuelo = false;
    }
  }
}
