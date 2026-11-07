// JSON exactly as the backend serialises it (docs/api-contract.md, M5).

Map<String, dynamic> confiabilidadJson({
  Object? porcentaje = 85.71,
  String nivel = 'ALTA',
  int confirmaciones = 18,
  int rechazos = 3,
  String? advertencia,
}) => {
  'porcentaje': porcentaje,
  'nivel': nivel,
  'confirmaciones': confirmaciones,
  'rechazos': rechazos,
  'advertencia': advertencia,
};

const advertenciaBaja =
    'Este reporte tiene pocas confirmaciones. Tómalo con precaución.';

Map<String, dynamic> pendienteJson({int id = 31, Map<String, dynamic>? conf}) =>
    {
      'id': id,
      'lugar': {'id': 7, 'nombre': 'Parque Kennedy', 'categoria': 'PARQUE'},
      'nivel': 'SATURADO',
      'fechaHora': '2026-10-05T12:00:00.000Z',
      'distanciaMetros': 420,
      'confiabilidad': conf ?? confiabilidadJson(),
    };

Map<String, dynamic> detalleJson({
  String? miValidacion,
  bool yaDenunciado = false,
  bool esPropio = false,
  Map<String, dynamic>? conf,
  String estado = 'VALIDADO',
}) => {
  'id': 31,
  'lugar': {'id': 7, 'nombre': 'Parque Kennedy', 'categoria': 'PARQUE'},
  'nivel': 'SATURADO',
  'fechaHora': '2026-10-05T12:00:00.000Z',
  'confiabilidad': conf ?? confiabilidadJson(),
  'estadoValidacion': estado,
  'miValidacion': miValidacion,
  'yaDenunciado': yaDenunciado,
  'esPropio': esPropio,
};

/// C7: the voter's points and tier after the vote is stored.
Map<String, dynamic> usuarioVotoJson({
  int puntos = 120,
  Object? tier = 'CROWD_EXPLORER',
}) => {'puntos': puntos, 'tier': tier};

/// C3: `201 { message: "¡Gracias por validar!", data: { validacion,
/// confiabilidad, estadoValidacion } }`, no karma block. With [usuario] it is
/// the C7 response (`data.usuario`); without it, the one of an older backend.
Map<String, dynamic> votoCreadoJson({
  String tipoAccion = 'CONFIRMAR',
  Map<String, dynamic>? usuario,
}) => {
  'message': '¡Gracias por validar!',
  'data': {
    'validacion': {
      'id': 9,
      'reporteId': 31,
      'tipoAccion': tipoAccion,
      'fechaHora': '2026-10-05T12:01:00.000Z',
    },
    'confiabilidad': confiabilidadJson(),
    'estadoValidacion': 'EN_VALIDACION',
    'usuario': ?usuario,
  },
};

Map<String, dynamic> estadoMioJson({
  int id = 5,
  String estado = 'EN_VALIDACION',
}) => {
  'reporteId': id,
  'lugar': {'id': 7, 'nombre': 'Parque Kennedy'},
  'nivel': 'MODERADO',
  'fechaHora': '2026-10-05T12:00:00.000Z',
  'confiabilidad': confiabilidadJson(
    porcentaje: null,
    nivel: 'INSUFICIENTE',
    confirmaciones: 1,
    rechazos: 1,
  ),
  'estadoValidacion': estado,
};

Map<String, dynamic> paginaJson(List<Object?> items) => {
  'message': 'ok',
  'data': {
    'items': items,
    'page': 1,
    'size': 20,
    'total': items.length,
    'totalPaginas': items.isEmpty ? 0 : 1,
  },
};
