/// Adapter pattern: port for push notifications. The app uses
/// `ReceptorPushFcm` (Firebase Cloud Messaging); tests use
/// `ReceptorPushNulo` or their own receivers, never Firebase.
abstract class ReceptorPush {
  Future<void> inicializar();

  /// Device token to register with the backend, or null when unavailable.
  Future<String?> obtenerToken();

  /// Ids of places opened from a notification tap.
  Stream<int> get lugarAbierto;
}
