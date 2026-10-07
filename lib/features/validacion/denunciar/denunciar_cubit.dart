import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/validacion.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/mensaje_error.dart';
import '../data/validacion_repository.dart';
import 'denunciar_state.dart';

/// HU 5.4: report a report as fraudulent.
class DenunciarCubit extends Cubit<DenunciarState> {
  static const int maxDetalle = 280;
  static const String errorSinMotivo =
      'Selecciona un motivo para enviar tu denuncia.';
  static const String errorSinDetalle = 'Describe brevemente el problema.';
  static const String errorDetalleLargo =
      'La descripción admite hasta $maxDetalle caracteres.';
  static const String mensajeYaRegistrada = 'Esta denuncia ya fue registrada.';

  final ValidacionRepository _repositorio;
  final int _reporteId;

  DenunciarCubit(this._repositorio, this._reporteId)
    : super(const DenunciarFormulario());

  Future<void> enviar(MotivoDenuncia? motivo, String detalle) async {
    final actual = state;
    if (isClosed || actual is! DenunciarFormulario || actual.enviando) return;
    final texto = detalle.trim();
    final error = motivo == null
        ? errorSinMotivo
        : motivo == MotivoDenuncia.otro && texto.isEmpty
        ? errorSinDetalle
        : texto.length > maxDetalle
        ? errorDetalleLargo
        : null;
    if (error != null) return emit(DenunciarFormulario(error: error));
    emit(const DenunciarFormulario(enviando: true));
    try {
      await _repositorio.denunciar(
        _reporteId,
        motivo!,
        detalle: motivo == MotivoDenuncia.otro ? texto : null,
      );
      if (!isClosed) emit(const DenunciarEnviado());
    } catch (e) {
      if (isClosed) return;
      final bloqueante =
          e is ApiException && const {404, 409, 422}.contains(e.status);
      emit(
        !bloqueante
            ? DenunciarFormulario(error: mensajeDeError(e))
            : DenunciarBloqueado(
                codigoDeError(e) == 'DENUNCIA_DUPLICADA'
                    ? mensajeYaRegistrada
                    : mensajeDeError(e),
              ),
      );
    }
  }
}
