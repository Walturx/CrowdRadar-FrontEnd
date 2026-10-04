// S9.1: every frozen route renders its placeholder page without exceptions.
import 'package:crowdradar/app/app.dart';
import 'package:crowdradar/app/dependencias.dart';
import 'package:crowdradar/core/config/entorno.dart';
import 'package:crowdradar/core/map/mapa_adapter.dart';
import 'package:crowdradar/core/map/tipos_mapa.dart';
import 'package:crowdradar/core/session/session_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/jwt_falso.dart';

/// Keeps app-level tests off the network (no OSM tiles).
class _MapaVacio implements MapaAdapter {
  @override
  Widget construirMapa({
    required PuntoGeografico centro,
    double zoom = 13,
    List<MarcadorLugar> marcadores = const [],
    required void Function(int lugarId) alTocarMarcador,
    void Function(LimitesMapa limites)? alMoverCamara,
    void Function(LimitesMapa limites)? alCamaraQuieta,
    PuntoGeografico? ubicacionUsuario,
  }) => const SizedBox.expand();
}

Future<void> _abrir(
  WidgetTester tester,
  String ruta, {
  bool admin = false,
}) async {
  final sesion = SessionService.instance..reiniciar();
  await sesion.iniciar('token', admin ? adminPrueba : usuarioPrueba);
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

const _pendiente = 'Pantalla en construcción';

void main() {
  tearDown(() => SessionService.instance.reiniciar());

  // (route, title, detail fragment)
  const usuario = [
    ('/mapa/explorar', 'Explorar lugares', _pendiente),
    ('/mapa/lugares/7', 'Detalle del lugar', 'Lugar #7'),
    ('/mapa/lugares/9/historial', 'Historial de aforo', 'Lugar #9'),
    ('/mapa/lugares/3/comparar', 'Comparar periodos', 'Lugar #3'),
    ('/mapa/lugares/4/mejor-horario', 'Mejor horario', 'Lugar #4'),
    ('/validar/reportes/12', 'Detalle del reporte', 'Reporte #12'),
    ('/favoritos/alertas', 'Alertas', _pendiente),
    ('/perfil/password', 'Cambiar contraseña', _pendiente),
    ('/perfil/reportes', 'Mis reportes', _pendiente),
    ('/perfil/validaciones', 'Estado de mis reportes', _pendiente),
  ];
  const admin = [
    ('/admin/reportes', 'Reportes denunciados', _pendiente),
    ('/admin/reportes/21', 'Revisión del reporte', 'Reporte #21'),
    ('/admin/usuarios', 'Usuarios', _pendiente),
    ('/admin/usuarios/31', 'Detalle del usuario', 'Usuario #31'),
  ];

  for (final (ruta, titulo, detalle) in usuario) {
    testWidgets('S9.1 $ruta renders "$titulo"', (tester) async {
      await _abrir(tester, ruta);

      expect(find.text(titulo), findsWidgets);
      expect(find.textContaining(detalle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final (ruta, titulo, detalle) in admin) {
    testWidgets('S9.1 $ruta renders "$titulo"', (tester) async {
      await _abrir(tester, ruta, admin: true);

      expect(find.text(titulo), findsWidgets);
      expect(find.textContaining(detalle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('S9.1 /recuperar is public and renders its placeholder', (
    tester,
  ) async {
    SessionService.instance.reiniciar();
    await tester.pumpWidget(
      CrowdRadarApp(
        dependencias: Dependencias.crear(
          const Entorno(usarFakes: true),
          SessionService.instance,
          mapaAdapter: _MapaVacio(),
        ),
        ubicacionInicial: '/recuperar',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recuperar contraseña'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
