import 'receptor_push.dart';

/// Change-0 implementation: no push, nothing emitted.
class ReceptorPushNulo implements ReceptorPush {
  @override
  Future<void> inicializar() async {}

  @override
  Future<String?> obtenerToken() async => null;

  @override
  Stream<int> get lugarAbierto => const Stream<int>.empty();
}
