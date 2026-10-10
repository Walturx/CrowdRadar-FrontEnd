import 'package:equatable/equatable.dart';

import '../../../core/models/moderacion.dart';

sealed class DenunciadosState extends Equatable {
  const DenunciadosState();

  @override
  List<Object?> get props => const [];
}

class DenunciadosCargando extends DenunciadosState {
  const DenunciadosCargando();
}

class DenunciadosCargado extends DenunciadosState {
  final List<ReporteDenunciado> reportes;

  /// Reports with pending denuncias on the server, not only the loaded ones.
  final int total;
  final int page;
  final bool hayMas;
  final bool cargandoMas;

  /// Notice for the user (failed refresh or next page).
  final String? aviso;

  const DenunciadosCargado({
    required this.reportes,
    required this.total,
    required this.page,
    required this.hayMas,
    this.cargandoMas = false,
    this.aviso,
  });

  /// HU 7.1 c3: nothing left to review.
  bool get estaVacia => reportes.isEmpty;

  DenunciadosCargado copiar({
    List<ReporteDenunciado>? reportes,
    int? total,
    int? page,
    bool? hayMas,
    bool? cargandoMas,
    String? aviso,
    bool sinAviso = false,
  }) => DenunciadosCargado(
    reportes: reportes ?? this.reportes,
    total: total ?? this.total,
    page: page ?? this.page,
    hayMas: hayMas ?? this.hayMas,
    cargandoMas: cargandoMas ?? this.cargandoMas,
    aviso: sinAviso ? null : aviso ?? this.aviso,
  );

  @override
  List<Object?> get props => [
    reportes,
    total,
    page,
    hayMas,
    cargandoMas,
    aviso,
  ];
}

class DenunciadosError extends DenunciadosState {
  final String mensaje;
  final String? codigo;
  final bool esSinConexion;

  const DenunciadosError(
    this.mensaje, {
    this.codigo,
    this.esSinConexion = false,
  });

  @override
  List<Object?> get props => [mensaje, codigo, esSinConexion];
}
