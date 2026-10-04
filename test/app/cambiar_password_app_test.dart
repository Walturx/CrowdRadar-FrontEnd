// HU 2.3: after a password change the session ends and the login explains why.
import 'package:crowdradar/app/app.dart';
import 'package:crowdradar/app/dependencias.dart';
import 'package:crowdradar/app/fakes/datos_fake.dart';
import 'package:crowdradar/core/config/entorno.dart';
import 'package:crowdradar/core/map/mapa_adapter.dart';
import 'package:crowdradar/core/map/tipos_mapa.dart';
import 'package:crowdradar/core/session/session_service.dart';
import 'package:crowdradar/features/perfil/cambiar_password/cambiar_password_cubit.dart';
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

void main() {
  tearDown(() => SessionService.instance.reiniciar());

  testWidgets('a password change signs out and the login shows the notice', (
    tester,
  ) async {
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
        ubicacionInicial: '/perfil/password',
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('campo-password-actual')),
      passwordFake,
    );
    await tester.enterText(
      find.byKey(const Key('campo-password-nueva')),
      'Nueva1234',
    );
    await tester.enterText(
      find.byKey(const Key('campo-password-confirmar')),
      'Nueva1234',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Cambiar contraseña'));
    // Deterministic: the fake answers instantly; let the navigation and the
    // snack bar entrance run without waiting for the notice to expire.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(sesion.token, isNull);
    expect(find.byKey(const Key('boton-iniciar-sesion')), findsOneWidget);
    expect(find.text(CambiarPasswordCubit.mensajeExito), findsOneWidget);
  });
}
