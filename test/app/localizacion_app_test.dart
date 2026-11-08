// CRO-68: the framework texts (tooltips, counters, tabs, pickers and
// dialogs) come from the Spanish (Peru) Material localizations, so TalkBack
// reads them in Spanish.
import 'package:crowdradar/app/app.dart';
import 'package:crowdradar/app/dependencias.dart';
import 'package:crowdradar/core/config/entorno.dart';
import 'package:crowdradar/core/map/mapa_adapter.dart';
import 'package:crowdradar/core/map/tipos_mapa.dart';
import 'package:crowdradar/core/session/session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fabrica_repositorios_fake.dart';
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

Future<void> _abrir(WidgetTester tester, String ruta) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final sesion = SessionService.instance..reiniciar();
  await sesion.iniciar('token', usuarioPrueba);
  await tester.pumpWidget(
    CrowdRadarApp(
      dependencias: Dependencias.crear(
        const Entorno(),
        sesion,
        repositorios: const FabricaRepositoriosFake(),
        mapaAdapter: _MapaVacio(),
      ),
      ubicacionInicial: ruta,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() => SessionService.instance.reiniciar());

  testWidgets('the back button is announced as "Atrás"', (tester) async {
    await _abrir(tester, '/perfil/acerca');

    expect(find.byTooltip('Atrás'), findsOneWidget);
    expect(find.byTooltip('Back'), findsNothing);
  });

  testWidgets(
    'framework texts for counters, tabs, pickers and dialogs are Spanish (Peru)',
    (tester) async {
      await _abrir(tester, '/perfil/acerca');

      final contexto = tester.element(find.byType(Scaffold).last);
      final textos = MaterialLocalizations.of(contexto);

      expect(Localizations.localeOf(contexto), const Locale('es', 'PE'));
      expect(
        textos.remainingTextFieldCharacterCount(280),
        'Quedan 280 caracteres',
      );
      expect(textos.tabLabel(tabIndex: 1, tabCount: 2), isNot(contains('Tab')));
      expect(textos.datePickerHelpText, isNot('Select date'));
      expect(textos.cancelButtonLabel, isNot('Cancel'));
    },
  );
}
