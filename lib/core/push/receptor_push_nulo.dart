import 'receptor_push.dart';

/// Null Object pattern: a [ReceptorPush] that does nothing (no token, no
/// taps), so the app never checks whether push exists.
class ReceptorPushNulo implements ReceptorPush {
  @override
  Future<void> inicializar() async {}

  @override
  Future<String?> obtenerToken() async => null;

  @override
  Stream<int> get lugarAbierto => const Stream<int>.empty();
}
