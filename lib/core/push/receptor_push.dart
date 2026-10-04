/// Frozen port for push notifications (FCM implementation arrives in M3).
abstract class ReceptorPush {
  Future<void> inicializar();

  /// Device token to register with the backend, or null when unavailable.
  Future<String?> obtenerToken();

  /// Ids of places opened from a notification tap.
  Stream<int> get lugarAbierto;
}
