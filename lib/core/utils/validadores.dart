/// Form validators shared by every screen. Return null when valid.
class Validadores {
  const Validadores._();

  static const String mensajeObligatorio = 'Este campo es obligatorio';

  static String? requerido(String? valor) =>
      valor == null || valor.trim().isEmpty ? mensajeObligatorio : null;

  static String? nombreApellido(String? valor) {
    final error = requerido(valor);
    if (error != null) return error;
    return valor!.trim().length < 2 ? 'Mínimo 2 caracteres' : null;
  }
}
