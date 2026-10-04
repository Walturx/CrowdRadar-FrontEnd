import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/mensaje_error.dart';
import '../data/perfil_repository.dart';
import 'editar_perfil_state.dart';

class EditarPerfilCubit extends Cubit<EditarPerfilState> {
  final PerfilRepository _repositorio;

  EditarPerfilCubit(this._repositorio) : super(const EditarPerfilEditando());

  Future<void> guardar(Map<String, dynamic> cambios) async {
    emit(const EditarPerfilGuardando());
    try {
      emit(EditarPerfilGuardado(await _repositorio.actualizar(cambios)));
    } catch (e) {
      emit(EditarPerfilFallido(
        mensajeDeError(e),
        codigo: codigoDeError(e),
        esSinConexion: esErrorSinConexion(e),
      ));
    }
  }
}
