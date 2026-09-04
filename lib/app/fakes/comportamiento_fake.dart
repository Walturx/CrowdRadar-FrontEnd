import '../../core/network/api_exception.dart';

/// Test-double knob shared by every fake repository: simulated [latencia] and
/// an optional [fallo] thrown on every call. The default is instant success.
class ComportamientoFake {
  final Duration latencia;
  final ApiException? fallo;

  const ComportamientoFake({this.latencia = Duration.zero, this.fallo});

  /// Waits [latencia], then throws [fallo] when one is configured.
  Future<void> aplicar() async {
    if (latencia > Duration.zero) await Future<void>.delayed(latencia);
    final error = fallo;
    if (error != null) throw error;
  }
}
