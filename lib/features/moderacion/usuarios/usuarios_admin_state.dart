import 'package:equatable/equatable.dart';

import '../../../core/models/moderacion.dart';

sealed class UsuariosAdminState extends Equatable {
  const UsuariosAdminState();

  @override
  List<Object?> get props => const [];
}

class UsuariosAdminCargando extends UsuariosAdminState {
  const UsuariosAdminCargando();
}

class UsuariosAdminCargado extends UsuariosAdminState {
  final List<UsuarioAdmin> usuarios;

  /// Matches of the current filters on the server, not only the loaded ones.
  final int total;
  final int page;
  final bool hayMas;

  /// Filters in effect (null [q] and [status] mean no filter).
  final String? q;
  final EstadoCuenta? status;
  final OrdenUsuarios orden;

  /// A filter change is loading; [usuarios] is still the previous result.
  final bool actualizando;
  final bool cargandoMas;

  /// Notice for the user (failed refresh or next page).
  final String? aviso;

  const UsuariosAdminCargado({
    required this.usuarios,
    required this.total,
    required this.page,
    required this.hayMas,
    required this.orden,
    this.q,
    this.status,
    this.actualizando = false,
    this.cargandoMas = false,
    this.aviso,
  });

  UsuariosAdminCargado copiar({
    List<UsuarioAdmin>? usuarios,
    int? page,
    bool? hayMas,
    bool? actualizando,
    bool? cargandoMas,
    String? aviso,
    bool sinAviso = false,
  }) => UsuariosAdminCargado(
    usuarios: usuarios ?? this.usuarios,
    total: total,
    page: page ?? this.page,
    hayMas: hayMas ?? this.hayMas,
    orden: orden,
    q: q,
    status: status,
    actualizando: actualizando ?? this.actualizando,
    cargandoMas: cargandoMas ?? this.cargandoMas,
    aviso: sinAviso ? null : aviso ?? this.aviso,
  );

  @override
  List<Object?> get props => [
    usuarios,
    total,
    page,
    hayMas,
    q,
    status,
    orden,
    actualizando,
    cargandoMas,
    aviso,
  ];
}

class UsuariosAdminError extends UsuariosAdminState {
  final String mensaje;
  final String? codigo;
  final bool esSinConexion;

  const UsuariosAdminError(
    this.mensaje, {
    this.codigo,
    this.esSinConexion = false,
  });

  @override
  List<Object?> get props => [mensaje, codigo, esSinConexion];
}
