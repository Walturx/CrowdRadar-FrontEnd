import 'dart:async';

import 'package:crowdradar/core/config/entorno.dart';
import 'package:crowdradar/core/network/api_client.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../fakes/registro_falso.dart';

/// The four transport/server failures every Cubit that talks HTTP must
/// survive. Each one carries the exact [ApiException] the repository boundary
/// throws for it, so Cubit tests stub `thenThrow(caso.error)`.
enum ErrorComun {
  timeout('timeout (15 s)'),
  sesionExpirada('401 sesión expirada'),
  servidor('5xx'),
  sinRed('sin red');

  final String nombre;

  const ErrorComun(this.nombre);

  ApiException get error => switch (this) {
    // Not hand-written: produced by the real ApiClient when a request
    // outlives its 15 s timeout (see [errorDeTimeout]).
    ErrorComun.timeout => _errorDeTimeout,
    ErrorComun.sesionExpirada => const ApiException(
      status: 401,
      message: 'No hay sesión activa',
      code: 'NO_AUTENTICADO',
    ),
    ErrorComun.servidor => const ApiException(
      status: 500,
      message: 'Error interno del servidor',
      code: 'ERROR_INTERNO',
    ),
    ErrorComun.sinRed => const ApiException.sinConexion(),
  };

  /// User-facing text the Cubits surface for this failure.
  String get mensaje => error.message;

  /// Whether the failure is flagged as a network problem (retry affordance).
  bool get esSinConexion => error.esSinConexion;
}

final ApiException _errorDeTimeout = errorDeTimeout();

/// Runs a request through the real [ApiClient] with a server that never
/// answers and advances fake time by [ApiClient.timeoutPorDefecto]; returns
/// the error the client throws. No real waiting.
ApiException errorDeTimeout() {
  Object? capturado;
  fakeAsync((async) {
    final api = ApiClient(
      MockClient((_) => Completer<http.Response>().future),
      const Entorno(apiUrl: 'http://api.test'),
      registro: RegistroFalso(),
    );
    api
        .get<Object?>('/api/x', parser: (d) => d)
        .then<void>((_) {}, onError: (Object e) => capturado = e);
    async.elapse(ApiClient.timeoutPorDefecto);
  });
  if (capturado is! ApiException) {
    fail('ApiClient did not time out after 15 s (got $capturado)');
  }
  return capturado as ApiException;
}

/// Declares one test per [ErrorComun], named `[<caso>] <descripcion>`.
void testErroresComunes(
  String descripcion,
  FutureOr<void> Function(ErrorComun caso) cuerpo,
) {
  for (final caso in ErrorComun.values) {
    test('[${caso.nombre}] $descripcion', () => cuerpo(caso));
  }
}
