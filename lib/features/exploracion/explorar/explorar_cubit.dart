import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/categoria_lugar.dart';
import '../../../core/models/nivel_saturacion.dart';
import '../../../core/utils/mensaje_error.dart';
import '../data/categoria_resumen.dart';
import '../data/exploracion_repository.dart';
import 'explorar_state.dart';

/// HU 3.5 / 3.6: the category list and the filters the user has chosen.
/// The chosen filters survive a failed categories load and its retry.
class ExplorarCubit extends Cubit<ExplorarState> {
  final ExploracionRepository _repositorio;

  ExplorarCubit(this._repositorio) : super(const ExplorarCargando());

  CategoriaLugar? _categoria;
  NivelSaturacion? _saturacion;

  /// A load while another is in flight is ignored.
  bool _enVuelo = false;

  Future<void> cargarCategorias() async {
    if (isClosed || _enVuelo) return;
    _enVuelo = true;
    emit(const ExplorarCargando());
    try {
      final categorias = await _repositorio.listarCategorias();
      if (isClosed) return;
      emit(_cargado(categorias));
    } catch (e) {
      if (isClosed) return;
      emit(
        ExplorarError(
          mensajeDeError(e),
          codigo: codigoDeError(e),
          esSinConexion: esErrorSinConexion(e),
        ),
      );
    } finally {
      _enVuelo = false;
    }
  }

  /// `null` means "Todos".
  void seleccionarCategoria(CategoriaLugar? categoria) {
    if (categoria == _categoria) return;
    _categoria = categoria;
    _reemitir();
  }

  /// `null` means "Todos".
  void seleccionarSaturacion(NivelSaturacion? saturacion) {
    if (saturacion == _saturacion) return;
    _saturacion = saturacion;
    _reemitir();
  }

  void _reemitir() {
    final actual = state;
    if (isClosed || actual is! ExplorarCargado) return;
    emit(_cargado(actual.categorias));
  }

  ExplorarCargado _cargado(List<CategoriaResumen> categorias) =>
      ExplorarCargado(
        categorias,
        categoria: _categoria,
        saturacion: _saturacion,
      );
}
