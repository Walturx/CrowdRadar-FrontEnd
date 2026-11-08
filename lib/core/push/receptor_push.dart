/// Adapter pattern: port for push notifications. Real delivery (FCM) is not
/// part of this build: the app uses [ReceptorPushNulo]; tests use their own
/// receivers.
abstract class ReceptorPush {
  Future<void> inicializar();

  /// Device token to register with the backend, or null when unavailable.
  Future<String?> obtenerToken();

  /// Ids of places opened from a notification tap.
  Stream<int> get lugarAbierto;
}
