import 'dart:convert';

import 'package:crowdradar/core/config/entorno.dart';
import 'package:crowdradar/core/network/api_client.dart';
import 'package:crowdradar/core/network/interceptores/interceptores_sesion.dart';
import 'package:crowdradar/core/session/session_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const entornoPrueba = Entorno(apiUrl: 'http://api.test');

http.Response respuestaJson(int status, Object? body) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// ApiClient wired like production (session interceptors) over a MockClient.
ApiClient apiClientPrueba(MockClientHandler handler, SessionService sesion) =>
    ApiClient(
      MockClient(handler),
      entornoPrueba,
      interceptores: interceptoresDeSesion(sesion),
    );
