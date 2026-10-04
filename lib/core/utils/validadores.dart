/// Form validators shared by every screen. Return null when valid.
class Validadores {
  const Validadores._();

  static const String mensajeObligatorio = 'Este campo es obligatorio';

  static String? requerido(String? valor) =>
      valor == null || valor.trim().isEmpty ? mensajeObligatorio : null;

  static final RegExp _celular = RegExp(r'^9\d{8}$');

  /// Optional; when present it mirrors the backend (`^9\d{8}$`).
  static String? telefono(String? valor) =>
      valor == null || valor.isEmpty || _celular.hasMatch(valor)
          ? null
          : 'Ingresá un celular de 9 dígitos que empiece en 9';

  /// Mirrors the backend minimum of 2 characters.
  static String? distrito(String? valor) =>
      (valor?.trim().length ?? 0) < 2 ? 'Ingresá tu distrito' : null;

  static String? nombreApellido(String? valor) {
    final error = requerido(valor);
    if (error != null) return error;
    return valor!.trim().length < 2 ? 'Mínimo 2 caracteres' : null;
  }
}
