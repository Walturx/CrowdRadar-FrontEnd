import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/mensaje_error.dart';
import '../data/perfil_repository.dart';
import 'editar_perfil_state.dart';

class EditarPerfilCubit extends Cubit<EditarPerfilState> {
  final PerfilRepository _repositorio;

  EditarPerfilCubit(this._repositorio) : super(const EditarPerfilEditando());

  /// A submit while another is in flight is ignored.
  bool _enVuelo = false;

  Future<void> guardar(Map<String, dynamic> cambios) async {
    if (_enVuelo) return;
    _enVuelo = true;
    emit(const EditarPerfilGuardando());
    try {
      emit(EditarPerfilGuardado(await _repositorio.actualizar(cambios)));
    } catch (e) {
      emit(
        EditarPerfilFallido(
          mensajeDeError(e),
          codigo: codigoDeError(e),
          esSinConexion: esErrorSinConexion(e),
        ),
      );
    } finally {
      _enVuelo = false;
    }
  }
}
