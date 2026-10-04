import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/http_error_util.dart';
import '../data/perfil_repository.dart';
import 'perfil_state.dart';

class PerfilCubit extends Cubit<PerfilState> {
  final PerfilRepository _repositorio;

  PerfilCubit(this._repositorio) : super(const PerfilCargando());

  Future<void> cargar() async {
    emit(const PerfilCargando());
    try {
      emit(PerfilCargado(await _repositorio.obtener()));
    } catch (e) {
      emit(PerfilError(mensajeDeError(e)));
    }
  }
}
