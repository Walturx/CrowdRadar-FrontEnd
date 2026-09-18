// M3 wiring: device registration on login/logout and push taps opening the place.
import 'dart:async';

import 'package:crowdradar/app/app.dart';
import 'package:crowdradar/app/dependencias.dart';
import 'package:crowdradar/app/fakes/alerta_repository_fake.dart';
import 'package:crowdradar/core/config/entorno.dart';
import 'package:crowdradar/core/map/mapa_adapter.dart';
import 'package:crowdradar/core/map/tipos_mapa.dart';
import 'package:crowdradar/core/push/receptor_push.dart';
import 'package:crowdradar/core/session/motivo_cierre.dart';
import 'package:crowdradar/features/alertas/data/alerta_repository.dart';
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

/// Records device calls without needing a session.
class _AlertasGrabadoras extends AlertaRepositoryFake {
  int registros = 0;
  int borrados = 0;

  _AlertasGrabadoras() : super(sembrar: false);

  @override
  Future<void> registrarDispositivo(String token, PlataformaPush p) async {
    registros++;
    return super.registrarDispositivo(token, p);
  }

  @override
  Future<void> eliminarDispositivo(String token) async {
    borrados++;
    return super.eliminarDispositivo(token);
  }
}

/// Emits a tap while it initializes, on a stream nobody buffers.
class _ReceptorEmisor extends _ReceptorFalso {
  final StreamController<int> directo = StreamController<int>.broadcast();

  @override
  Future<void> inicializar() async {
    directo.add(2);
  }

  @override
  Stream<int> get lugarAbierto => directo.stream;
}

/// Push receiver double: a buffered stream, so a tap that happened before the
/// app listened (cold start) is still delivered.
class _ReceptorFalso implements ReceptorPush {
  final StreamController<int> toques = StreamController<int>();
  int inicializaciones = 0;
  String? token = 'tok-dev';

  @override
  Future<void> inicializar() async => inicializaciones++;

  @override
  Future<String?> obtenerToken() async => token;

  @override
  Stream<int> get lugarAbierto => toques.stream;
}

void main() {
  late SessionService sesion;
  late _ReceptorFalso receptor;
  late Dependencias deps;

  AlertaRepositoryFake alertas() => deps.alertaRepository as AlertaRepositoryFake;

  AlertaRepositoryFake? alertasPropias;

  Future<void> abrir(
    WidgetTester tester, {
    String ruta = '/favoritos',
    bool conSesion = true,
  }) async {
    tester.view.physicalSize = const Size(2400, 6000);
    addTearDown(tester.view.resetPhysicalSize);
    if (conSesion) await sesion.iniciar('token', usuarioPrueba);
    deps = Dependencias.crear(
      const Entorno(usarFakes: true),
      sesion,
      mapaAdapter: _MapaVacio(),
      receptorPush: receptor,
      alertaRepository: alertasPropias,
    );
    await tester.pumpWidget(
      CrowdRadarApp(dependencias: deps, ubicacionInicial: ruta),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    sesion = SessionService.instance..reiniciar();
    receptor = _ReceptorFalso();
    alertasPropias = null;
  });

  tearDown(() {
    receptor.toques.close();
    sesion.reiniciar();
  });

  group('device registration', () {
    testWidgets('a restored session registers the device token', (
      tester,
    ) async {
      await abrir(tester);

      expect(alertas().dispositivos, ['tok-dev']);
      expect(receptor.inicializaciones, 1);
    });

    testWidgets('logging in registers it', (tester) async {
      await abrir(tester, conSesion: false);
      expect(alertas().dispositivos, isEmpty);

      await sesion.iniciar('token', usuarioPrueba);
      // The map (default landing) animates forever: pump instead of settling.
      await tester.pump();
      await tester.pump();

      expect(alertas().dispositivos, ['tok-dev']);
    });

    testWidgets('without a token nothing is registered and the app works', (
      tester,
    ) async {
      receptor.token = null;

      await abrir(tester);

      expect(alertas().dispositivos, isEmpty);
      expect(find.text('Favoritos'), findsWidgets);
    });

    testWidgets('logging out removes it while the session is still valid', (
      tester,
    ) async {
      await abrir(tester, ruta: '/perfil');
      expect(alertas().dispositivos, ['tok-dev']);

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cerrar sesión'));
      await tester.pumpAndSettle();

      // The fake needs a live session to accept the DELETE, so an empty list
      // proves the call went out before the session was cleared.
      expect(alertas().dispositivos, isEmpty);
      expect(find.text('Iniciar sesión'), findsWidgets);
    });
  });

  group('device registration edge cases', () {
    testWidgets('a restored session plus SesionIniciada registers once (R4-802)', (
      tester,
    ) async {
      final grabadoras = alertasPropias = _AlertasGrabadoras();
      await abrir(tester);

      await sesion.iniciar('token', usuarioPrueba);
      await tester.pump();
      await tester.pump();

      expect(grabadoras.registros, 1);
    });

    testWidgets('an expired session also tries to remove it (R4-803)', (
      tester,
    ) async {
      final grabadoras = alertasPropias = _AlertasGrabadoras();
      await abrir(tester);

      await sesion.expirar(MotivoCierre.sesionExpirada);
      await tester.pump();
      await tester.pump();

      expect(grabadoras.borrados, 1);
    });

    testWidgets('a user sign out removes it once, not twice', (tester) async {
      final grabadoras = alertasPropias = _AlertasGrabadoras();
      await abrir(tester, ruta: '/perfil');

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(grabadoras.borrados, 1);
    });
  });

  group('push taps', () {
    testWidgets('a tap before the session is ready opens after sign in (R3-807)', (
      tester,
    ) async {
      await abrir(tester, ruta: '/login', conSesion: false);

      receptor.toques.add(1);
      await tester.pumpAndSettle();
      expect(find.text('Av. Larco 345, Miraflores'), findsNothing);

      await sesion.iniciar('token', usuarioPrueba);
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Av. Larco 345, Miraflores'), findsOneWidget);
    });

    testWidgets('a pending tap is dropped on sign out', (tester) async {
      await abrir(tester, ruta: '/login', conSesion: false);
      receptor.toques.add(1);
      await tester.pumpAndSettle();

      await sesion.cerrar(MotivoCierre.usuario);
      await tester.pumpAndSettle();
      await sesion.iniciar('token', usuarioPrueba);
      // The map landing animates forever: pump instead of settling.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Av. Larco 345, Miraflores'), findsNothing);
    });

    testWidgets('a tap emitted while the receiver initializes is not lost (R3-807)', (
      tester,
    ) async {
      receptor = _ReceptorEmisor();

      await abrir(tester);

      expect(find.text('Av. Angamos Este 1000, Surquillo'), findsOneWidget);
    });

    testWidgets('a tap opens that place', (tester) async {
      await abrir(tester);

      receptor.toques.add(1);
      await tester.pumpAndSettle();

      expect(find.text('Av. Larco 345, Miraflores'), findsOneWidget);
    });

    testWidgets('a tap that opened the app (cold start) is delivered', (
      tester,
    ) async {
      receptor.toques.add(2);

      await abrir(tester);

      expect(find.text('Av. Angamos Este 1000, Surquillo'), findsOneWidget);
    });

    testWidgets('a tap without a session is ignored', (tester) async {
      await abrir(tester, ruta: '/login', conSesion: false);

      receptor.toques.add(1);
      await tester.pumpAndSettle();

      expect(find.text('Av. Larco 345, Miraflores'), findsNothing);
      expect(find.text('Iniciar sesión'), findsWidgets);
    });
  });
}
