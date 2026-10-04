import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/mensaje_error.dart';
import 'analitica_state.dart';

/// Load/retry skeleton of an analytics screen: subclasses only say how to
/// fetch the data and when it counts as "no data".
abstract class AnaliticaCubit<T> extends Cubit<AnaliticaState<T>> {
  AnaliticaCubit() : super(AnaliticaCargando<T>());

  /// A load while another is in flight is ignored.
  bool _enVuelo = false;

  bool get enVuelo => _enVuelo;

  Future<T> obtener();

  /// True when [datos] hold nothing to draw.
  bool estaVacio(T datos);

  /// Backend explanation shown with the empty state.
  String? mensajeDe(T datos);

  Future<void> cargar() async {
    if (_enVuelo) return;
    _enVuelo = true;
    emit(AnaliticaCargando<T>());
    try {
      final datos = await obtener();
      if (isClosed) return;
      emit(
        estaVacio(datos)
            ? AnaliticaSinDatos<T>(mensajeDe(datos))
            : AnaliticaCargado<T>(datos),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        AnaliticaError<T>(
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
