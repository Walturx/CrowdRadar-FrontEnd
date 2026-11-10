/// Adapter pattern: port for push notifications. The app uses
/// `ReceptorPushFcm` (Firebase Cloud Messaging); tests use
/// `ReceptorPushNulo` or their own receivers, never Firebase.
abstract class ReceptorPush {
  Future<void> inicializar();

  /// Device token to register with the backend, or null when unavailable.
  Future<String?> obtenerToken();

  /// Ids of places opened from a notification tap.
  Stream<int> get lugarAbierto;

  /// Messages received while the app is in the foreground, where the system
  /// shows no notification: the app shows its own notice and reloads the
  /// alert inbox. A broadcast stream, so several listeners can share it.
  Stream<MensajePrimerPlano> get mensajesEnPrimerPlano;
}

/// A push received with the app in the foreground: the notification texts and
/// the place in its `data.lugarId` (null when missing or non-numeric, so the
/// notice offers no place to open).
class MensajePrimerPlano {
  final String? titulo;
  final String? cuerpo;
  final int? lugarId;

  const MensajePrimerPlano({this.titulo, this.cuerpo, this.lugarId});
}
