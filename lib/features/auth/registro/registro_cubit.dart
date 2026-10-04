import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/mensaje_error.dart';
import '../data/auth_repository.dart';
import 'registro_state.dart';

class RegistroCubit extends Cubit<RegistroState> {
  final AuthRepository _repositorio;

  RegistroCubit(this._repositorio) : super(const RegistroInicial());

  /// A submit while another is in flight is ignored.
  bool _enVuelo = false;

  Future<void> registrar({
    required String nombre,
    required String apellido,
    required String email,
    required String password,
    required String telefono,
    required String distrito,
  }) async {
    if (_enVuelo) return;
    _enVuelo = true;
    emit(const RegistroEnviando());
    try {
      await _repositorio.registrar(
        nombre: nombre,
        apellido: apellido,
        email: email,
        password: password,
        telefono: telefono,
        distrito: distrito,
      );
      emit(const RegistroExitoso());
    } catch (e) {
      emit(
        RegistroFallido(
          mensajeDeError(e),
          erroresPorCampo: erroresPorCampo(e),
          codigo: codigoDeError(e),
          esSinConexion: esErrorSinConexion(e),
        ),
      );
    } finally {
      _enVuelo = false;
    }
  }
}
