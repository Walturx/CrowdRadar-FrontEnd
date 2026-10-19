// Repeatable frame-timing baseline (profile mode) against the real backend
// with the bench seed (scripts/bench in the backend repo).
//
// Each scenario logs the frames of a scripted interaction with
// `watchPerformance`; test_driver/perf_driver.dart writes the summaries to
// build/perf/. Login happens once per role (the backend allows 10 logins per
// 15 min per IP). Admin scenarios are skipped without PERF_ADMIN_PASSWORD.

import 'package:crowdradar/app/app.dart';
import 'package:crowdradar/app/dependencias.dart';
import 'package:crowdradar/app/rutas.dart';
import 'package:crowdradar/core/config/entorno.dart';
import 'package:crowdradar/core/session/motivo_cierre.dart';
import 'package:crowdradar/core/session/session_service.dart';
import 'package:crowdradar/core/storage/memoria_token_storage.dart';
import 'package:crowdradar/features/lugares/buscar/buscar_lugar_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _emailUsuario = String.fromEnvironment(
  'PERF_USER_EMAIL',
  defaultValue: 'bench001@bench.crowdradar.local',
);
const _passwordUsuario = String.fromEnvironment(
  'PERF_USER_PASSWORD',
  defaultValue: 'BenchCrowdRadar2026',
);
const _emailAdmin = String.fromEnvironment(
  'PERF_ADMIN_EMAIL',
  defaultValue: 'admin@crowdradar.local',
);
const _passwordAdmin = String.fromEnvironment('PERF_ADMIN_PASSWORD');

/// "Cargar más" taps before measuring: 20 items per page -> ~100 rows.
const _paginasExtra = 4;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final sesion = SessionService.instance..configurar(MemoriaTokenStorage());
  final deps = Dependencias.crear(const Entorno(), sesion);

  Future<void> iniciar(String email, String password) async {
    await sesion.cerrar(MotivoCierre.usuario);
    await deps.authRepository.iniciarSesion(email, password);
  }

  Future<void> abrir(WidgetTester tester, String ruta) async {
    await tester.pumpWidget(
      CrowdRadarApp(
        key: UniqueKey(),
        dependencias: deps,
        ubicacionInicial: ruta,
      ),
    );
  }

  /// Pumps until [finder] matches (real time; the backend answers in ms).
  Future<void> esperar(
    WidgetTester tester,
    Finder finder, {
    Duration max = const Duration(seconds: 30),
  }) async {
    final limite = DateTime.now().add(max);
    while (finder.evaluate().isEmpty) {
      if (DateTime.now().isAfter(limite)) {
        final textos = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data)
            .whereType<String>()
            .join(' | ');
        fail('Timeout esperando $finder. Textos visibles: $textos');
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> asentar(WidgetTester tester, [int ms = 800]) =>
      tester.pump(Duration(milliseconds: ms));

  Finder lista() => find.byType(ListView).first;

  /// Grows a paginated list by tapping "Cargar más" (outside measurement).
  Future<void> expandir(WidgetTester tester) async {
    final boton = find.text('Cargar más');
    for (var i = 0; i < _paginasExtra; i++) {
      for (var j = 0; j < 40 && boton.evaluate().isEmpty; j++) {
        await tester.drag(lista(), const Offset(0, -1500));
        await asentar(tester, 300);
      }
      if (boton.evaluate().isEmpty) return;
      await tester.ensureVisible(boton);
      await asentar(tester, 300);
      await tester.tap(boton);
      await asentar(tester, 1500);
    }
    for (var j = 0; j < 40; j++) {
      await tester.drag(lista(), const Offset(0, 3000));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await asentar(tester);
  }

  /// 5 flings down and 5 up, letting each ballistic scroll finish.
  Future<void> desplazar(WidgetTester tester) async {
    for (final dy in [-700.0, 700.0]) {
      for (var i = 0; i < 5; i++) {
        await tester.fling(lista(), Offset(0, dy), 2500);
        await asentar(tester, 1200);
      }
    }
  }

  Future<int> contarFilas(WidgetTester tester) async =>
      tester.widget<ListView>(lista()).semanticChildCount ?? -1;

  setUpAll(() {
    binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  });

  group('usuario', () {
    setUpAll(() => iniciar(_emailUsuario, _passwordUsuario));

    testWidgets('mapa_pan_zoom', (tester) async {
      await abrir(tester, Rutas.mapa);
      final mapa = find.byType(FlutterMap);
      await esperar(tester, mapa);
      await asentar(tester, 4000); // markers + first tiles
      await binding.watchPerformance(() async {
        for (final d in const [
          Offset(-300, 0),
          Offset(0, -300),
          Offset(300, 0),
          Offset(0, 300),
        ]) {
          await tester.timedDrag(mapa, d, const Duration(milliseconds: 600));
          await asentar(tester);
        }
        // Pinch zoom in and out around the center.
        final centro = tester.getCenter(mapa);
        for (final abrirDedos in [true, false]) {
          final a0 = abrirDedos ? -40.0 : -160.0;
          final a1 = abrirDedos ? -160.0 : -40.0;
          final g1 = await tester.startGesture(centro + Offset(a0, 0));
          final g2 = await tester.startGesture(
            centro + Offset(-a0, 0),
            pointer: 2,
          );
          const pasos = 20;
          for (var i = 1; i <= pasos; i++) {
            final x = a0 + (a1 - a0) * i / pasos;
            await g1.moveTo(centro + Offset(x, 0));
            await g2.moveTo(centro + Offset(-x, 0));
            await tester.pump(const Duration(milliseconds: 16));
          }
          await g1.up();
          await g2.up();
          await asentar(tester, 1500);
        }
      }, reportKey: 'mapa_pan_zoom');
    });

    testWidgets('mis_reportes_scroll', (tester) async {
      await abrir(tester, Rutas.perfilReportes);
      await esperar(tester, find.byType(ListView));
      await asentar(tester, 1000);
      await expandir(tester);
      debugPrint('mis_reportes filas: ${await contarFilas(tester)}');
      await binding.watchPerformance(
        () => desplazar(tester),
        reportKey: 'mis_reportes_scroll',
      );
    });

    testWidgets('buscar_lugar_scroll', (tester) async {
      await abrir(tester, Rutas.buscarLugar);
      await esperar(tester, find.byType(TextField));
      // The integration binding keeps the real IME (enterText never reaches
      // onChanged), so the query goes straight to the page's cubit.
      tester
          .element(find.byType(TextField))
          .read<BuscarLugarCubit>()
          .alCambiarTexto('Bench');
      await esperar(tester, find.byType(ListView));
      await asentar(tester, 1000);
      await binding.watchPerformance(
        () => desplazar(tester),
        reportKey: 'buscar_lugar_scroll',
      );
    });
  });

  group(
    'admin',
    () {
      setUpAll(() => iniciar(_emailAdmin, _passwordAdmin));

      testWidgets('admin_denunciados_scroll', (tester) async {
        await abrir(tester, Rutas.adminReportes);
        await esperar(tester, find.byType(ListView));
        await asentar(tester, 1000);
        await expandir(tester);
        await binding.watchPerformance(
          () => desplazar(tester),
          reportKey: 'admin_denunciados_scroll',
        );
      });

      testWidgets('admin_usuarios_scroll', (tester) async {
        await abrir(tester, Rutas.adminUsuarios);
        await esperar(tester, find.byType(ListView));
        await asentar(tester, 1000);
        await expandir(tester);
        await binding.watchPerformance(
          () => desplazar(tester),
          reportKey: 'admin_usuarios_scroll',
        );
      });
    },
    skip: _passwordAdmin.isEmpty
        ? 'Sin --dart-define=PERF_ADMIN_PASSWORD'
        : false,
  );
}
