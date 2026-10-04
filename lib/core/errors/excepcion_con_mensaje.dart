/// A domain failure that carries text safe to show to the user.
///
/// `mensajeDeError` prefers [mensajeUsuario] over the generic message.
abstract interface class ExcepcionConMensaje implements Exception {
  String get mensajeUsuario;
}
