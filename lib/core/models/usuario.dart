import 'package:equatable/equatable.dart';

import 'enum_api.dart';
import 'tier_usuario.dart';

/// Value object: equality is by every field so states holding it compare by value.
class Usuario extends Equatable {
  final int? id;
  final String? nombre;
  final String? apellido;
  final String? email;
  final String? telefono;
  final String? rol;
  final String? distrito;
  final String? status;
  final String? createdAt;
  final String? updatedAt;

  /// Points the backend computes from validated reports and matching votes.
  final int puntos;

  /// Tier the backend assigns from [puntos]; shown as is, never derived here.
  final TierUsuario tier;

  const Usuario({
    this.id,
    this.nombre,
    this.apellido,
    this.email,
    this.telefono,
    this.rol,
    this.distrito,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.puntos = 0,
    this.tier = TierUsuario.crowdBaby,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    id: json['id'] as int?,
    nombre: json['nombre'] as String?,
    apellido: json['apellido'] as String?,
    email: json['email'] as String?,
    telefono: json['telefono'] as String?,
    rol: json['rol'] as String?,
    distrito: json['distrito'] as String?,
    status: json['status'] as String?,
    createdAt: json['createdAt'] as String?,
    updatedAt: json['updatedAt'] as String?,
    puntos: json['puntos'] is num ? (json['puntos'] as num).toInt() : 0,
    tier: TierUsuario.desdeApi(json['tier']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'apellido': apellido,
    'email': email,
    'telefono': telefono,
    'rol': rol,
    'distrito': distrito,
    'status': status,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'puntos': puntos,
    'tier': valorApi(tier),
  };

  @override
  List<Object?> get props => [
    id,
    nombre,
    apellido,
    email,
    telefono,
    rol,
    distrito,
    status,
    createdAt,
    updatedAt,
    puntos,
    tier,
  ];

  Usuario copyWith({
    int? id,
    String? nombre,
    String? apellido,
    String? email,
    String? telefono,
    String? rol,
    String? distrito,
    String? status,
    String? createdAt,
    String? updatedAt,
    int? puntos,
    TierUsuario? tier,
  }) {
    return Usuario(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      rol: rol ?? this.rol,
      distrito: distrito ?? this.distrito,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      puntos: puntos ?? this.puntos,
      tier: tier ?? this.tier,
    );
  }
}
