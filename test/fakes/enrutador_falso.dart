import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Minimal router for widget tests: [ruta] renders [pantalla]; every path in
/// [otras] renders a `RUTA <path>` marker so navigation is observable.
/// No guards, no network.
GoRouter enrutadorDe({
  required String ruta,
  required Widget pantalla,
  String inicial = '/inicio',
  List<String> otras = const ['/mapa', '/inicio'],
}) => GoRouter(
  initialLocation: inicial,
  routes: [
    GoRoute(path: ruta, builder: (_, _) => pantalla),
    for (final o in otras)
      if (o != ruta)
        GoRoute(
          path: o,
          builder: (_, _) => Scaffold(body: Text('RUTA $o')),
        ),
  ],
);
