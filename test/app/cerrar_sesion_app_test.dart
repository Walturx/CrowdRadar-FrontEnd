// HU 2.4 and the session notice, end to end with the in-memory fakes.
import 'package:crowdradar/app/app.dart';
import 'package:crowdradar/app/dependencias.dart';
import 'package:crowdradar/core/config/entorno.dart';
import 'package:crowdradar/core/map/mapa_adapter.dart';
import 'package:crowdradar/core/map/tipos_mapa.dart';
import 'package:crowdradar/core/session/motivo_cierre.dart';
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

Future<SessionService> _abrir(WidgetTester tester, String ruta) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final sesion = SessionService.instance..reiniciar();
  await sesion.iniciar('token', usuarioPrueba);
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
  return sesion;
}

void main() {
  tearDown(() => SessionService.instance.reiniciar());

  testWidgets('HU 2.4 confirming the dialog ends the session and shows the login', (
    tester,
  ) async {
    final sesion = await _abrir(tester, '/perfil');

    await tester.ensureVisible(find.text('Cerrar sesión'));
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(sesion.token, isNull);
    expect(find.widgetWithText(ElevatedButton, 'Iniciar sesión'), findsOneWidget);
    // Going back must not return to a protected screen.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ElevatedButton, 'Iniciar sesión'), findsOneWidget);
  });

  testWidgets('an expired session lands on the login with "Tu sesión terminó"', (
    tester,
  ) async {
    final sesion = await _abrir(tester, '/perfil');

    await tester.runAsync(() => sesion.expirar(MotivoCierre.sesionExpirada));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ElevatedButton, 'Iniciar sesión'), findsOneWidget);
    expect(find.text('Tu sesión terminó'), findsOneWidget);
  });

  testWidgets('R3-1206 a suspended account lands on the login with its notice', (
    tester,
  ) async {
    final sesion = await _abrir(tester, '/perfil');

    await tester.runAsync(() => sesion.expirar(MotivoCierre.cuentaSuspendida));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('boton-iniciar-sesion')), findsOneWidget);
    expect(find.text('Tu cuenta fue suspendida'), findsOneWidget);
    expect(find.text('Tu sesión terminó'), findsNothing);
  });

  testWidgets('R3-1206 a password-change close lands on the login without the expiry notice', (
    tester,
  ) async {
    final sesion = await _abrir(tester, '/perfil');

    await tester.runAsync(() => sesion.cerrar(MotivoCierre.passwordCambiada));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('boton-iniciar-sesion')), findsOneWidget);
    expect(find.text('Tu sesión terminó'), findsNothing);
    expect(find.text('Tu cuenta fue suspendida'), findsNothing);
  });

  testWidgets('a user sign out shows no session-ended notice', (tester) async {
    final sesion = await _abrir(tester, '/perfil');

    await tester.runAsync(() => sesion.cerrar(MotivoCierre.usuario));
    await tester.pumpAndSettle();

    expect(find.text('Tu sesión terminó'), findsNothing);
  });

  testWidgets('/perfil/acerca renders the About screen', (tester) async {
    await _abrir(tester, '/perfil/acerca');

    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
  });
}
