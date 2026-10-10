import '../../../core/models/validacion.dart';

/// User-facing name of a denuncia motivo.
String etiquetaMotivo(MotivoDenuncia motivo) => switch (motivo) {
  MotivoDenuncia.informacionFalsa => 'Información falsa',
  MotivoDenuncia.spam => 'Spam o repetido',
  MotivoDenuncia.contenidoInapropiado => 'Contenido inapropiado',
  MotivoDenuncia.otro => 'Otro motivo',
};

/// "1 denuncia" / "4 denuncias".
String textoDenuncias(int cantidad) =>
    cantidad == 1 ? '1 denuncia' : '$cantidad denuncias';
