import 'package:crowdradar/app/app.dart';
import 'package:crowdradar/app/dependencias.dart';
import 'package:crowdradar/app/fakes/datos_fake.dart';
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

  testWidgets('the Reportes tab shows the moderation queue', (tester) async {
    await _abrirAdmin(tester, '/admin/reportes');

    expect(find.text('3 REPORTES POR REVISAR'), findsOneWidget);
    expect(find.text('Jockey Plaza'), findsOneWidget);
  });

  testWidgets('the admin lands on the user directory with fake data', (
    tester,
  ) async {
    await _abrirAdmin(tester, '/admin/usuarios');

    expect(find.text('5 USUARIOS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('CRO-63 the admin reaches the moderation panel', () {
    Future<SessionService> abrirSinSesion(WidgetTester tester) async {
      final sesion = SessionService.instance..reiniciar();
      await tester.pumpWidget(
        CrowdRadarApp(
          dependencias: Dependencias.crear(
            const Entorno(usarFakes: true),
            sesion,
            mapaAdapter: _MapaVacio(),
          ),
          ubicacionInicial: '/login',
        ),
      );
      await tester.pumpAndSettle();
      return sesion;
    }

    void expectPanelDeModeracion() {
      expect(find.text('Reportes denunciados'), findsOneWidget);
      final nav = find.byType(NavigationBar);
      expect(
        find.descendant(of: nav, matching: find.text('Reportes')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: nav, matching: find.text('Usuarios')),
        findsOneWidget,
      );
      expect(find.text('Mapa'), findsNothing);
    }

    testWidgets('an ADMIN login opens Reportes denunciados', (tester) async {
      await abrirSinSesion(tester);

      await tester.enterText(find.byType(TextFormField).at(0), emailAdminFake);
      await tester.enterText(find.byType(TextFormField).at(1), passwordFake);
      await tester.tap(find.byKey(const Key('boton-iniciar-sesion')));
      await tester.pumpAndSettle();

      expectPanelDeModeracion();
    });

    testWidgets('a restored ADMIN session opens the panel on start', (
      tester,
    ) async {
      // The app always starts on /mapa; the session decides where it lands.
      await _abrirAdmin(tester, '/mapa');

      expectPanelDeModeracion();
    });

    testWidgets('"Cerrar sesión" in the panel returns the ADMIN to the login', (
      tester,
    ) async {
      await _abrirAdmin(tester, '/admin/reportes');

      await tester.tap(find.byTooltip('Cerrar sesión'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(SessionService.instance.token, isNull);
      expect(find.byKey(const Key('boton-iniciar-sesion')), findsOneWidget);
    });

    testWidgets('"Cerrar sesión" is also on the Usuarios tab', (tester) async {
      await _abrirAdmin(tester, '/admin/usuarios');

      expect(find.byTooltip('Cerrar sesión'), findsOneWidget);
    });
  });
}
