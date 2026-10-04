import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/mensaje_error.dart';
import '../data/lugar_repository.dart';
import 'buscar_lugar_state.dart';

/// Search by name: debounced, and never calls the API below [minimoCaracteres].
class BuscarLugarCubit extends Cubit<BuscarLugarState> {
  static const Duration esperaTecleo = Duration(milliseconds: 400);
  static const int minimoCaracteres = 2;
  static const int limiteResultados = 50;
  static const String mensajeSinConexion =
      'No pudimos realizar la búsqueda. Revisa tu conexión e inténtalo de nuevo.';
  static const String mensajeError =
      'No pudimos realizar la búsqueda. Inténtalo de nuevo.';

  final LugarRepository _repositorio;
  final Duration _espera;

  Timer? _temporizador;
  String? _ultimaConsulta;

  /// Identifies the latest request so a slower, older response is dropped.
  int _solicitud = 0;

  BuscarLugarCubit(this._repositorio, {Duration espera = esperaTecleo})
    : _espera = espera,
      super(const BuscarInicial());

  void alCambiarTexto(String texto) {
    final consulta = texto.trim();
    _temporizador?.cancel();
    if (consulta.length >= minimoCaracteres && consulta == _ultimaConsulta) {
      return;
    }
    if (consulta.length < minimoCaracteres) {
      _solicitud++;
      _ultimaConsulta = null;
      if (state is! BuscarInicial) emit(const BuscarInicial());
      return;
    }
    _temporizador = Timer(_espera, () => _buscar(consulta));
  }

  /// Repeats the last search; nothing to repeat before the first one.
  Future<void> reintentar() async {
    _temporizador?.cancel();
    final consulta = _ultimaConsulta;
    if (consulta != null) await _buscar(consulta);
  }

  Future<void> _buscar(String consulta) async {
    _ultimaConsulta = consulta;
    final solicitud = ++_solicitud;
    emit(const BuscarBuscando());
    try {
      final res = await _repositorio.buscar(
        q: consulta,
        limite: limiteResultados,
      );
      if (_obsoleta(solicitud)) return;
      emit(
        res.estaVacia
            ? BuscarSinResultados(
                consulta,
                mensajeServidor: res.mensaje.isEmpty ? null : res.mensaje,
              )
            : BuscarResultados(res.items, consulta: consulta),
      );
    } catch (e) {
      if (_obsoleta(solicitud)) return;
      emit(
        BuscarError(
          esErrorSinConexion(e) ? mensajeSinConexion : mensajeError,
          consulta: consulta,
          codigo: codigoDeError(e),
          esSinConexion: esErrorSinConexion(e),
        ),
      );
    }
  }

  bool _obsoleta(int solicitud) => isClosed || solicitud != _solicitud;

  @override
  Future<void> close() {
    _temporizador?.cancel();
    return super.close();
  }
}
