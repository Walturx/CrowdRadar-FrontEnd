import 'package:crowdradar/app/app.dart';
import 'package:crowdradar/app/dependencias.dart';
import 'package:crowdradar/core/config/entorno.dart';
import 'package:crowdradar/core/map/mapa_adapter.dart';
import 'package:crowdradar/core/map/tipos_mapa.dart';
import 'package:crowdradar/core/session/session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/jwt_falso.dart';

class _MapaVacio implements MapaAdapter {
  @override
  Widget construirMapa({
    required PuntoGeografico centro,
    double zoom = 13,
    List<MarcadorLugar> marcadores = const [],
    required void Function(int lugarId) alTocarMarcador,
    EventosMapa eventos = const EventosMapa(),
    PuntoGeografico? ubicacionUsuario,
  }) => const SizedBox.expand();
}

Future<void> _abrirAdmin(WidgetTester tester, String ruta) async {
  final sesion = SessionService.instance..reiniciar();
  await sesion.iniciar('token', adminPrueba);
  await tester.pumpWidget(
    CrowdRadarApp(
      dependencias: Dependencias.crear(
        const Entorno(usarFakes: true),
        sesion,
        mapaAdapter: _MapaVacio(),
      ),
      ubicacionInicial: ruta,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() => SessionService.instance.reiniciar());

  testWidgets('the admin shell has the Reportes and Usuarios tabs', (
    tester,
  ) async {
    await _abrirAdmin(tester, '/admin/reportes');

    final nav = find.byType(NavigationBar);
    expect(nav, findsOneWidget);
    expect(
      find.descendant(of: nav, matching: find.text('Reportes')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: nav, matching: find.text('Usuarios')),
      findsOneWidget,
    );
  });

  testWidgets('the Usuarios tab opens the user directory', (tester) async {
    await _abrirAdmin(tester, '/admin/reportes');

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Usuarios'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Usuarios registrados'), findsOneWidget);
    expect(find.text('Carlos Méndez'), findsOneWidget);
  });

  testWidgets('the admin lands on the user directory with fake data', (
    tester,
  ) async {
    await _abrirAdmin(tester, '/admin/usuarios');

    expect(find.text('5 USUARIOS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
