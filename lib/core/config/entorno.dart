/// Build-time environment, read from `--dart-define`.
class Entorno {
  static const String apiUrlPorDefecto = 'http://10.0.2.2:3000';

  final String apiUrl;
  final bool usarFakes;

  const Entorno({this.apiUrl = apiUrlPorDefecto, this.usarFakes = false});

  factory Entorno.desdeDartDefine() => const Entorno(
        apiUrl: String.fromEnvironment('API_URL', defaultValue: apiUrlPorDefecto),
        usarFakes: bool.fromEnvironment('USAR_FAKES'),
      );
}
