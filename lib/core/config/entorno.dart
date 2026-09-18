/// Singleton-style configuration: build-time environment read once from
/// `--dart-define` and shared through the composition root.
class Entorno {
  /// Shown in "Acerca de"; keep it equal to `version:` in pubspec.yaml.
  static const String version = '1.0.0';

  static const String apiUrlPorDefecto = 'http://10.0.2.2:3000';

  final String apiUrl;
  final bool usarFakes;

  const Entorno({this.apiUrl = apiUrlPorDefecto, this.usarFakes = false});

  factory Entorno.desdeDartDefine() => const Entorno(
        apiUrl: String.fromEnvironment('API_URL', defaultValue: apiUrlPorDefecto),
        usarFakes: bool.fromEnvironment('USAR_FAKES'),
      );
}
