// M3 wiring: the unread badge on the Favoritos tab, the alerts list opened from
// it and the refresh when the app returns to the foreground.
import 'package:crowdradar/app/app.dart';
import 'package:crowdradar/app/dependencias.dart';
import 'package:crowdradar/app/fakes/alerta_repository_fake.dart';
import 'package:crowdradar/core/config/entorno.dart';
import 'package:crowdradar/core/map/mapa_adapter.dart';
import 'package:crowdradar/core/map/tipos_mapa.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
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

void main() {
  late SessionService sesion;
  late Dependencias deps;

  AlertaRepositoryFake alertas() => deps.alertaRepository as AlertaRepositoryFake;

  Future<void> abrir(WidgetTester tester, {String ruta = '/favoritos'}) async {
    tester.view.physicalSize = const Size(2400, 6000);
    addTearDown(tester.view.resetPhysicalSize);
    await sesion.iniciar('token', usuarioPrueba);
    deps = Dependencias.crear(
      const Entorno(usarFakes: true),
      sesion,
      mapaAdapter: _MapaVacio(),
    );
    await tester.pumpWidget(
      CrowdRadarApp(dependencias: deps, ubicacionInicial: ruta),
    );
    await tester.pumpAndSettle();
  }

  Finder insignia() => find.byKey(const Key('insignia-favoritos'));

  setUp(() => sesion = SessionService.instance..reiniciar());

  tearDown(() => sesion.reiniciar());

  group('alerts badge', () {
    testWidgets('shows the unread count on the Favoritos tab', (tester) async {
      await abrir(tester);

      expect(insignia(), findsOneWidget);
      expect(
        tester.widget<Text>(
          find.descendant(of: insignia(), matching: find.byType(Text)),
        ).data,
        '1',
      );
    });

    testWidgets('resuming the app refreshes the count', (tester) async {
      await abrir(tester);
      alertas().emitir(3, NivelSaturacion.tranquilo, NivelSaturacion.saturado);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(
        tester.widget<Text>(
          find.descendant(of: insignia(), matching: find.byType(Text)),
        ).data,
        '2',
      );
    });

    testWidgets('reading the alert from the list clears the badge', (
      tester,
    ) async {
      await abrir(tester, ruta: '/favoritos');

      await tester.tap(find.byKey(const Key('ir-alertas')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Parque Kennedy ahora está Saturado'));
      await tester.pumpAndSettle();

      expect(find.text('Av. Larco 345, Miraflores'), findsOneWidget);
      expect(insignia(), findsNothing);
    });
  });
}
