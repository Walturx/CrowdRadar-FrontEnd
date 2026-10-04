// The place detail route renders the real screen (no longer a placeholder).
import 'package:crowdradar/app/app.dart';
import 'package:crowdradar/app/dependencias.dart';
import 'package:crowdradar/core/config/entorno.dart';
import 'package:crowdradar/core/session/session_service.dart';
import 'package:crowdradar/features/lugares/buscar/buscar_lugar_page.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/jwt_falso.dart';

Future<void> _abrir(WidgetTester tester, String ruta) async {
  final sesion = SessionService.instance..reiniciar();
  await sesion.iniciar('token', usuarioPrueba);
  await tester.pumpWidget(
    CrowdRadarApp(
      dependencias: Dependencias.crear(const Entorno(usarFakes: true), sesion),
      ubicacionInicial: ruta,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() => SessionService.instance.reiniciar());

  testWidgets('/mapa/lugares/1 shows the seeded place from the fake', (
    tester,
  ) async {
    await _abrir(tester, '/mapa/lugares/1');

    expect(find.text('Av. Larco 345, Miraflores'), findsOneWidget);
    expect(find.text('Parque'), findsWidgets);
    expect(find.textContaining('Pantalla en construcción'), findsNothing);
  });

  testWidgets('/mapa/buscar opens the place search', (tester) async {
    await _abrir(tester, '/mapa/buscar');

    expect(find.text(BuscarLugarPage.ayuda), findsOneWidget);
  });

  testWidgets('/mapa/lugares/9999 shows the not-found state', (tester) async {
    await _abrir(tester, '/mapa/lugares/9999');

    expect(find.text('Información no disponible'), findsOneWidget);
    expect(find.text('Este lugar ya no está disponible.'), findsOneWidget);
  });
}
