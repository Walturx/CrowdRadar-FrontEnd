// JSON exactly as the backend serialises it (docs/api-contract.md, M6;
// src/dto/response/moderacion/ModeracionResponseDTO.ts).

Map<String, dynamic> paginaJson(
  List<Map<String, dynamic>> items, {
  int page = 1,
  int size = 20,
  int? total,
}) => {
  'message': 'ok',
  'data': {
    'items': items,
    'page': page,
    'size': size,
    'total': total ?? items.length,
    'totalPaginas': items.isEmpty ? 0 : 1,
  },
};

Map<String, dynamic> datosJson(Object? data) => {'message': 'ok', 'data': data};

Map<String, dynamic> reporteDenunciadoJson({
  int id = 201,
  int pendientes = 4,
}) => {
  'reporteId': id,
  'lugar': {'id': 7, 'nombre': 'Jockey Plaza', 'categoria': 'CENTRO_COMERCIAL'},
  'autor': {'id': 31, 'nombre': 'Carlos', 'apellido': 'Mendez'},
  'nivel': 'TRANQUILO',
  'fechaHora': '2026-10-05T12:00:00.000Z',
  'pendientes': pendientes,
  'ultimaDenunciaEn': '2026-10-05T12:10:00.000Z',
};

Map<String, dynamic> detalleReporteJson({String estado = 'ACTIVO'}) => {
  'reporteId': 201,
  'lugar': {'id': 7, 'nombre': 'Jockey Plaza', 'categoria': 'CENTRO_COMERCIAL'},
  'autor': {
    'id': 31,
    'nombre': 'Carlos',
    'apellido': 'Mendez',
    'email': 'carlos.mendez@correo.pe',
  },
  'nivel': 'TRANQUILO',
  'estado': estado,
  'fechaHora': '2026-10-05T12:00:00.000Z',
  'pendientes': 4,
  'motivos': [
    {'motivo': 'INFORMACION_FALSA', 'total': 2},
    {'motivo': 'CONTENIDO_INAPROPIADO', 'total': 1},
    {'motivo': 'SPAM', 'total': 1},
  ],
};

Map<String, dynamic> resolucionJson({String estado = 'ELIMINADO'}) => {
  'reporteId': 201,
  'estado': estado,
  'denunciasResueltas': 4,
};

Map<String, dynamic> sancionJson({
  String fechaFin = '2026-10-12T12:00:00.000Z',
}) => {
  'id': 9,
  'usuarioId': 12,
  'dias': 7,
  'motivo': 'Spam reiterado en reportes',
  'fechaInicio': '2026-10-05T12:00:00.000Z',
  'fechaFin': fechaFin,
};

Map<String, dynamic> usuarioJson({
  int id = 12,
  String status = 'ACTIVO',
  Map<String, dynamic>? sancion,
}) => {
  'id': id,
  'nombre': 'Lucia',
  'apellido': 'Paredes',
  'email': 'lucia.paredes@correo.pe',
  'rol': 'USUARIO',
  'status': status,
  'puntosKarma': 40,
  'sancionVigente': sancion,
};

Map<String, dynamic> detalleUsuarioJson({
  String status = 'ACTIVO',
  Map<String, dynamic>? sancion,
}) => {
  ...usuarioJson(status: status, sancion: sancion),
  'reportesPublicados': 32,
  'reportesDenunciados': 5,
};
