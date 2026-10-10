import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/moderacion.dart';
import '../../../core/utils/mensaje_error.dart';
import '../data/moderacion_repository.dart';
import 'usuarios_admin_state.dart';

/// HU 7.2 / 7.4: paginated user directory with search, status filter and sort.
class UsuariosAdminCubit extends Cubit<UsuariosAdminState> {
  static const Duration esperaBusqueda = Duration(milliseconds: 400);
  static const int tamanoPagina = 20;

  /// The API rejects a `q` shorter than this (400).
  static const int busquedaMinima = 2;

  final ModeracionRepository _repositorio;
  final Duration _espera;

  UsuariosAdminCubit(this._repositorio, {Duration espera = esperaBusqueda})
    : _espera = espera,
      super(const UsuariosAdminCargando());

  String? _q;
  EstadoCuenta? _status;
  OrdenUsuarios _orden = OrdenUsuarios.recientes;
  Timer? _temporizador;
  bool _cargandoMas = false;

  /// Bumped by every reload so an older, slower answer is dropped.
  int _secuencia = 0;

  /// (Re)loads the first page with the current filters.
  Future<void> cargar() async {
    if (isClosed) return;
    final secuencia = ++_secuencia;
    _cargandoMas = false;
    final actual = state;
    emit(
      actual is UsuariosAdminCargado
          ? actual.copiar(
              actualizando: true,
              cargandoMas: false,
              sinAviso: true,
            )
          : const UsuariosAdminCargando(),
    );
    try {
      final pagina = await _repositorio.usuarios(
        q: _q,
        status: _status,
        orden: _orden,
        page: 1,
        size: tamanoPagina,
      );
      if (isClosed || secuencia != _secuencia) return;
      emit(
        UsuariosAdminCargado(
          usuarios: pagina.items,
          total: pagina.total,
          page: pagina.page,
          hayMas: pagina.hayMas,
          q: _q,
          status: _status,
          orden: _orden,
        ),
      );
    } catch (e) {
      if (isClosed || secuencia != _secuencia) return;
      final ahora = state;
      emit(
        ahora is UsuariosAdminCargado
            ? ahora.copiar(actualizando: false, aviso: mensajeDeError(e))
            : UsuariosAdminError(
                mensajeDeError(e),
                codigo: codigoDeError(e),
                esSinConexion: esErrorSinConexion(e),
              ),
      );
    }
  }

  /// Debounced search by name or email; under [busquedaMinima] characters
  /// it behaves like clearing the search.
  void buscar(String texto) {
    _temporizador?.cancel();
    _temporizador = Timer(_espera, () {
      final limpio = texto.trim();
      final nuevo = limpio.length >= busquedaMinima ? limpio : null;
      if (nuevo == _q) return;
      _q = nuevo;
      cargar();
    });
  }

  Future<void> filtrar(EstadoCuenta? status) {
    _status = status;
    return cargar();
  }

  Future<void> ordenar(OrdenUsuarios orden) {
    _orden = orden;
    return cargar();
  }

  Future<void> cargarMas() async {
    final actual = state;
    if (isClosed ||
        _cargandoMas ||
        actual is! UsuariosAdminCargado ||
        !actual.hayMas) {
      return;
    }
    _cargandoMas = true;
    final secuencia = _secuencia;
    emit(actual.copiar(cargandoMas: true));
    try {
      final pagina = await _repositorio.usuarios(
        q: _q,
        status: _status,
        orden: _orden,
        page: actual.page + 1,
        size: tamanoPagina,
      );
      if (isClosed || secuencia != _secuencia) return;
      final ahora = state;
      if (ahora is! UsuariosAdminCargado) return;
      emit(
        ahora.copiar(
          usuarios: [...ahora.usuarios, ...pagina.items],
          page: pagina.page,
          hayMas: pagina.hayMas,
          cargandoMas: false,
        ),
      );
    } catch (e) {
      if (isClosed || secuencia != _secuencia) return;
      final ahora = state;
      if (ahora is UsuariosAdminCargado) {
        emit(ahora.copiar(cargandoMas: false, aviso: mensajeDeError(e)));
      }
    } finally {
      if (secuencia == _secuencia) _cargandoMas = false;
    }
  }

  void descartarAviso() {
    final actual = state;
    if (isClosed || actual is! UsuariosAdminCargado || actual.aviso == null) {
      return;
    }
    emit(actual.copiar(sinAviso: true));
  }

  @override
  Future<void> close() {
    _temporizador?.cancel();
    return super.close();
  }
}
