import 'package:http/http.dart' as http;

/// Factory Method pattern: the single place that constructs the `http.Client`.
///
/// Keeps `package:http` inside `core/network`; callers receive a client from
/// [crear] and tests can swap the product by passing their own client to `ApiClient`.
class ClienteHttpFactory {
  const ClienteHttpFactory();

  http.Client crear() => http.Client();
}
