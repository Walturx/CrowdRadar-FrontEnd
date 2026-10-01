import 'package:crowdradar/app/fakes/comportamiento_fake.dart';
import 'package:crowdradar/app/fakes/favorito_repository_fake.dart';
import 'package:crowdradar/app/fakes/reporte_repository_fake.dart';
import 'package:crowdradar/core/map/tipos_mapa.dart';
import 'package:crowdradar/core/models/categoria_lugar.dart';
import 'package:crowdradar/core/models/lugar_detalle.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/features/favoritos/data/favorito_repository.dart';
import 'package:crowdradar/features/lugares/data/lugar_repository.dart';
import 'package:crowdradar/features/lugares/detalle/detalle_lugar_page.dart';
import 'package:crowdradar/features/reportes/data/reporte_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/lugar_repo_falso.dart';

const _centro = PuntoGeografico(-12.1219, -77.0268);

LugarDetalle _detalle({
  NivelSaturacion nivel = NivelSaturacion.moderado,
  int minutos = 5,
  int reportes = 18,
  String? mensaje,
  String? horario,
}) => LugarDetalle(
  id: 1,
  nombre: 'Parque Kennedy',
  categoria: CategoriaLugar.parque,
  direccion: 'Av. Larco 345, Miraflores',
  latitud: -12.1219,
  longitud: -77.0297,
  horarioAtencion: horario,
  saturacion: SaturacionLugar(
    nivel: nivel,
    actualizadoEn: nivel == NivelSaturacion.sinInformacion
        ? null
        : DateTime.now().subtract(Duration(minutes: minutos, seconds: 10)),
    reportesRecientes: reportes,
    mensaje: mensaje,
  ),
);

void main() {
  late RepoLugarFalso repo;
  late FavoritoRepositoryFake favoritos;

  Future<void> abrir(
    WidgetTester tester, {
    PuntoGeografico? centro = _centro,
  }) async {
    tester.view.physicalSize = const Size(800, 2400);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<LugarRepository>.value(value: repo),
          RepositoryProvider<FavoritoRepository>.value(value: favoritos),
          RepositoryProvider<ReporteRepository>.value(
            value: ReporteRepositoryFake(),
          ),
        ],
        child: MaterialApp(
          home: DetalleLugarPage(lugarId: 1, centroMapa: centro),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  setUp(() => favoritos = FavoritoRepositoryFake());

  group('reportar', () {
    testWidgets(
      'the button opens the sheet and a sent report reloads the detail',
      (tester) async {
        repo = RepoLugarFalso(alObtener: (_) async => _detalle());
        await abrir(tester);
        expect(repo.detallesPedidos, [1]);

        await tester.tap(find.text('Reportar saturación'));
        await tester.pumpAndSettle();
        expect(find.text('¿Qué tan lleno está?'), findsOneWidget);

        await tester.tap(find.text('Saturado'));
        await tester.pump();
        await tester.tap(find.text('Enviar reporte'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Listo'));
        await tester.pumpAndSettle();

        expect(find.text('¿Qué tan lleno está?'), findsNothing);
        expect(repo.detallesPedidos, [1, 1]);
      },
    );

    testWidgets('dismissing the sheet without sending does not reload', (
      tester,
    ) async {
      repo = RepoLugarFalso(alObtener: (_) async => _detalle());
      await abrir(tester);

      await tester.tap(find.text('Reportar saturación'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('¿Qué tan lleno está?'), findsNothing);
      expect(repo.detallesPedidos, [1]);
    });

    testWidgets('the button is absent while loading and on error', (
      tester,
    ) async {
      repo = RepoLugarFalso(
        alObtener: (_) async =>
            throw const ApiException(status: 500, message: 'x'),
      );
      await abrir(tester);

      expect(find.text('Reportar saturación'), findsNothing);
    });
  });

  group('with saturation information', () {
    testWidgets('shows name, category with distance, level and freshness', (
      tester,
    ) async {
      repo = RepoLugarFalso(alObtener: (_) async => _detalle());
      await abrir(tester);

      expect(repo.detallesPedidos, [1]);
      expect(find.text('Parque Kennedy'), findsWidgets);
      expect(find.text('Parque · 315 m'), findsOneWidget);
      expect(find.text('Moderado'), findsOneWidget);
      expect(find.text('Actualizado hace 5 min · 18 reportes'), findsOneWidget);
    });

    testWidgets('the information block lists the address, not name/category', (
      tester,
    ) async {
      repo = RepoLugarFalso(alObtener: (_) async => _detalle());
      await abrir(tester);

      expect(find.text('Dirección'), findsOneWidget);
      expect(find.text('Av. Larco 345, Miraflores'), findsOneWidget);
      expect(find.text('Nombre'), findsNothing);
      expect(find.text('Categoría'), findsNothing);
    });

    testWidgets('without a known map centre the distance is omitted', (
      tester,
    ) async {
      repo = RepoLugarFalso(alObtener: (_) async => _detalle());
      await abrir(tester, centro: null);

      expect(find.text('Parque'), findsOneWidget);
      expect(find.textContaining('Parque ·'), findsNothing);
    });

    testWidgets('a single report is singular', (tester) async {
      repo = RepoLugarFalso(
        alObtener: (_) async => _detalle(reportes: 1, minutos: 12),
      );
      await abrir(tester);

      expect(find.text('Actualizado hace 12 min · 1 reporte'), findsOneWidget);
    });

    testWidgets('opening hours show only when the place has them', (
      tester,
    ) async {
      repo = RepoLugarFalso(
        alObtener: (_) async => _detalle(horario: '06:00-22:00'),
      );
      await abrir(tester);

      expect(find.text('Horario'), findsOneWidget);
      expect(find.text('06:00-22:00'), findsOneWidget);
    });

    testWidgets('no opening hours, no Horario row', (tester) async {
      repo = RepoLugarFalso(alObtener: (_) async => _detalle());
      await abrir(tester);

      expect(find.text('Horario'), findsNothing);
    });
  });

  group('without information (HU 3.2 c3)', () {
    testWidgets('says there is no information and shows the server message', (
      tester,
    ) async {
      repo = RepoLugarFalso(
        alObtener: (_) async => _detalle(
          nivel: NivelSaturacion.sinInformacion,
          reportes: 0,
          mensaje:
              'Aún no hay reportes suficientes para determinar la saturación de este lugar.',
        ),
      );
      await abrir(tester);

      expect(find.text('Sin información'), findsOneWidget);
      expect(
        find.text(
          'Aún no hay reportes suficientes para determinar la saturación de este lugar.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Actualizado'), findsNothing);
    });

    testWidgets('falls back to the HU text when the server sends none', (
      tester,
    ) async {
      repo = RepoLugarFalso(
        alObtener: (_) async =>
            _detalle(nivel: NivelSaturacion.sinInformacion, reportes: 0),
      );
      await abrir(tester);

      expect(
        find.text(
          'Aún no hay reportes suficientes para determinar la saturación de este lugar.',
        ),
        findsOneWidget,
      );
    });
  });

  group('errors (HU 3.3 c3)', () {
    testWidgets('shows the unavailable message and Reintentar loads again', (
      tester,
    ) async {
      var falla = true;
      repo = RepoLugarFalso(
        alObtener: (_) async {
          if (falla) throw const ApiException.sinConexion();
          return _detalle();
        },
      );
      await abrir(tester);

      expect(find.text('Información no disponible'), findsOneWidget);
      expect(
        find.text(
          'No pudimos obtener la información de este lugar. Inténtalo más tarde.',
        ),
        findsOneWidget,
      );

      falla = false;
      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Información no disponible'), findsNothing);
      expect(find.text('Moderado'), findsOneWidget);
    });

    testWidgets('a 404 explains the place is gone and offers no retry', (
      tester,
    ) async {
      repo = RepoLugarFalso(
        alObtener: (_) async => throw const ApiException(
          status: 404,
          message: 'No se pudo obtener la información del lugar.',
          code: 'LUGAR_NO_ENCONTRADO',
        ),
      );
      await abrir(tester);

      expect(find.text('Información no disponible'), findsOneWidget);
      expect(find.text('Este lugar ya no está disponible.'), findsOneWidget);
      expect(find.text('Reintentar'), findsNothing);
    });
  });

  group('favorite', () {
    testWidgets('the heart toggles the favorite and the repository follows', (
      tester,
    ) async {
      repo = RepoLugarFalso(alObtener: (_) async => _detalle());
      await abrir(tester);
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);

      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect((await favoritos.listar()).items.single.lugarId, 1);
    });

    testWidgets('a failure shows its message and keeps the heart', (
      tester,
    ) async {
      favoritos = FavoritoRepositoryFake(
        comportamiento: const ComportamientoFake(
          fallo: ApiException(status: 500, message: 'Servidor caído'),
        ),
      );
      repo = RepoLugarFalso(alObtener: (_) async => _detalle());
      await abrir(tester);

      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pump();
      await tester.pump();

      expect(find.text('Servidor caído'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });
  });
}
