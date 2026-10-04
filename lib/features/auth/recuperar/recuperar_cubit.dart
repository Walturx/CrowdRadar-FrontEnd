import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/mensaje_error.dart';
import '../../../core/utils/mensaje_espera.dart';
import '../data/auth_repository.dart';
import 'recuperar_state.dart';

/// HU 2.1: asks for a password recovery link. The success text is neutral on
/// purpose; only a DETALLADA server answers 404 `CUENTA_NO_EXISTE`.
class RecuperarCubit extends Cubit<RecuperarState> {
  static const String mensajeNeutral =
      'Si el correo está registrado, te enviamos un enlace para restablecer tu contraseña.';
  static const String mensajeCorreoInvalido = 'Ingresá un correo válido';
  static const String mensajeCuentaNoExiste = 'Ese correo no está registrado';
  static const String codigoCuentaNoExiste = 'CUENTA_NO_EXISTE';

  static final RegExp _formatoCorreo = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final AuthRepository _repositorio;

  RecuperarCubit(this._repositorio) : super(const RecuperarInicial());

  /// A submit while another is in flight is ignored.
  bool _enVuelo = false;

  Future<void> enviar(String email) async {
    if (_enVuelo) return;
    final correo = email.trim();
    if (!_formatoCorreo.hasMatch(correo)) {
      emit(const RecuperarFallido(mensajeCorreoInvalido));
      return;
    }
    _enVuelo = true;
    emit(const RecuperarEnviando());
    try {
      await _repositorio.solicitarRecuperacion(correo);
      _emitir(const RecuperarEnviado(mensajeNeutral));
    } catch (e) {
      final codigo = codigoDeError(e);
      _emitir(RecuperarFallido(
        codigo == codigoCuentaNoExiste
            ? mensajeCuentaNoExiste
            : esLimiteDeIntentos(e)
                ? mensajeEspera(esperaDeError(e))
                : mensajeDeError(e),
        codigo: codigo,
        esSinConexion: esErrorSinConexion(e),
        reintentarEnSegundos: esperaDeError(e),
      ));
    } finally {
      _enVuelo = false;
    }
  }

  void _emitir(RecuperarState estado) {
    if (!isClosed) emit(estado);
  }
}
