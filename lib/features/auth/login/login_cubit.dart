import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/mensaje_error.dart';
import '../data/auth_repository.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthRepository _repositorio;

  LoginCubit(this._repositorio) : super(const LoginInicial());

  Future<void> iniciarSesion(String email, String password) async {
    emit(const LoginEnviando());
    try {
      emit(LoginExitoso(await _repositorio.iniciarSesion(email, password)));
    } catch (e) {
      emit(LoginFallido(
        mensajeDeError(e),
        codigo: codigoDeError(e),
        esSinConexion: esErrorSinConexion(e),
      ));
    }
  }
}
