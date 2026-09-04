import 'dart:async';

import '../api_exception.dart';

/// Mutable outgoing request seen by interceptors.
class SolicitudApi {
  final String metodo;
  final Uri uri;
  final Map<String, String> headers;
  final Object? body;

  SolicitudApi({
    required this.metodo,
    required this.uri,
    required this.headers,
    this.body,
  });
}

/// Strategy / chain of responsibility: each link inspects or mutates traffic.
abstract class InterceptorApi {
  void antesDeEnviar(SolicitudApi solicitud) {}

  FutureOr<void> alRecibirError(ApiException error, SolicitudApi solicitud) {}
}
