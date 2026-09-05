import 'package:equatable/equatable.dart';

import '../models/usuario.dart';

/// Minimal user data kept for the active session.
class UsuarioSesion extends Equatable {
  static const String rolAdmin = 'ADMIN';

  final int? id;
  final String? nombre;
  final String? apellido;
  final String? email;
  final String? rol;
  final String? status;

  const UsuarioSesion({
    this.id,
    this.nombre,
    this.apellido,
    this.email,
    this.rol,
    this.status,
  });

  factory UsuarioSesion.desdeUsuario(Usuario u) => UsuarioSesion(
        id: u.id,
        nombre: u.nombre,
        apellido: u.apellido,
        email: u.email,
        rol: u.rol,
        status: u.status,
      );

  factory UsuarioSesion.fromJson(Map<String, dynamic> json) => UsuarioSesion(
        id: json['id'] as int?,
        nombre: json['nombre'] as String?,
        apellido: json['apellido'] as String?,
        email: json['email'] as String?,
        rol: json['rol'] as String?,
        status: json['status'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'apellido': apellido,
        'email': email,
        'rol': rol,
        'status': status,
      };

  bool get esAdmin => rol == rolAdmin;

  @override
  List<Object?> get props => [id, nombre, apellido, email, rol, status];
}
