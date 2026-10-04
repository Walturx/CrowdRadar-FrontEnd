import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/mensaje_error.dart';
import '../../../core/utils/mensaje_espera.dart';
import '../data/perfil_repository.dart';
import 'cambiar_password_state.dart';
import '../../../core/utils/politica_password.dart';

/// HU 2.3: changes the password. The client checks the match and the policy
/// first; the server errors (400 list, 422, 429) are mapped from the API.
class CambiarPasswordCubit extends Cubit<CambiarPasswordState> {
  static const String mensajeExito =
      'Contraseña actualizada. Inicia sesión con tu nueva contraseña.';
  static const String mensajeNoCoinciden = 'Las contraseñas no coinciden';
  static const String mensajeResultadoIncierto =
      'No pudimos confirmar el cambio. Si no podés entrar con la contraseña '
      'actual, probá con la nueva.';
  static const String mensajeNoCumple =
      'La nueva contraseña no cumple los requisitos';

  final PerfilRepository _repositorio;

  CambiarPasswordCubit(this._repositorio)
      : super(const CambiarPasswordInicial());

  /// A submit while another is in flight is ignored.
  bool _enVuelo = false;

  Future<void> cambiar({
    required String actual,
    required String nueva,
    required String confirmar,
  }) async {
    if (_enVuelo) return;
    if (nueva != confirmar) {
      emit(const CambiarPasswordFallido(mensajeNoCoinciden));
      return;
    }
    final incumplidos = requisitosIncumplidos(nueva);
    if (incumplidos.isNotEmpty) {
      emit(CambiarPasswordFallido(
        mensajeNoCumple,
        requisitosIncumplidos: [for (final r in incumplidos) r.texto],
      ));
      return;
    }
    _enVuelo = true;
    emit(const CambiarPasswordEnviando());
    try {
      await _repositorio.cambiarPassword(
        actual: actual,
        nueva: nueva,
        confirmar: confirmar,
      );
      _emitir(const CambiarPasswordExitoso(mensajeExito));
    } catch (e) {
      // Offline or timed out after sending: the server may have applied it.
      final incierto = esErrorSinConexion(e);
      _emitir(CambiarPasswordFallido(
        incierto
            ? mensajeResultadoIncierto
            : esLimiteDeIntentos(e)
                ? mensajeEspera(esperaDeError(e))
                : mensajeDeError(e),
        // Not `erroresPorCampo`: several unmet rules share one field.
        requisitosIncumplidos: e is ApiException
            ? [for (final error in e.errors) error.mensaje]
            : const [],
        codigo: codigoDeError(e),
        esSinConexion: incierto,
        resultadoIncierto: incierto,
        reintentarEnSegundos: esperaDeError(e),
      ));
    } finally {
      _enVuelo = false;
    }
  }

  void _emitir(CambiarPasswordState estado) {
    if (!isClosed) emit(estado);
  }
}
