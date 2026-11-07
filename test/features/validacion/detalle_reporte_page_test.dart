import 'package:crowdradar/app/fakes/validacion_repository_fake.dart';
import 'package:crowdradar/core/models/validacion.dart';
import 'package:crowdradar/features/validacion/data/validacion_repository.dart';
import 'package:crowdradar/features/validacion/detalle_reporte/detalle_reporte_page.dart';
import 'package:crowdradar/features/validacion/widgets/chip_estado_validacion.dart';
import 'package:crowdradar/features/validacion/widgets/tarjeta_reporte.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'json_validacion.dart';

/// The fake as an older backend: the vote response has no `usuario` (C7).
class _RepoSinTier extends ValidacionRepositoryFake {
  @override
  Future<ResultadoVoto> validar(
    int reporteId,
    TipoAccionValidacion accion,
  ) async {
    final v = await super.validar(reporteId, accion);
    return ResultadoVoto(
      accion: v.accion,
      confiabilidad: v.confiabilidad,
      estadoValidacion: v.estadoValidacion,
    );
  }
}

/// The fake, but `GET /api/reportes/:id` answers with a fixed [detalle].
class _RepoConDetalle extends ValidacionRepositoryFake {
  final DetalleReporte detalle;

  _RepoConDetalle(this.detalle);

  @override
  Future<DetalleReporte> obtenerReporte(int reporteId) async => detalle;
}

/// [f] inside the snack bar on screen.
Finder _enAviso(Finder f) =>
    find.descendant(of: find.byType(SnackBar), matching: f);

/// Any tier badge image, or the one at [ruta].
Finder _insigniaTier([String? ruta]) => find.byWidgetPredicate(
  (w) =>
      w is Image &&
      w.image is AssetImage &&
      (ruta == null
          ? (w.image as AssetImage).assetName.startsWith('assets/images/tier_')
          : (w.image as AssetImage).assetName == ruta),
);

void main() {
  late ValidacionRepositoryFake repo;

  Future<void> abrir(WidgetTester tester, int id) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      RepositoryProvider<ValidacionRepository>.value(
        value: repo,
        child: MaterialApp(home: DetalleReportePage(reporteId: id)),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() => repo = ValidacionRepositoryFake());

  testWidgets('ALTA shows the percentage, level and raw counts', (
    tester,
  ) async {
    await abrir(tester, 101);

    expect(find.text('Detalle del reporte'), findsOneWidget);
    expect(find.text('Parque Kennedy'), findsOneWidget);
    expect(find.text('Confiabilidad del reporte'), findsOneWidget);
    expect(find.text('86%'), findsOneWidget);
    expect(find.text('Confiabilidad Alta'), findsOneWidget);
    expect(find.text('18 confirman · 3 rechazan'), findsOneWidget);
    expect(
      find.text('Basado en confirmaciones de la comunidad'),
      findsOneWidget,
    );
  });

  group('S24 the detail reads as the Validar card', () {
    /// [f] inside the report card.
    Finder enTarjeta(Finder f) =>
        find.descendant(of: find.byType(TarjetaReporte), matching: f);

    testWidgets('the report sits in the shared card with the same pieces', (
      tester,
    ) async {
      await abrir(tester, 101);

      expect(find.byType(TarjetaReporte), findsOneWidget);
      expect(enTarjeta(find.byType(Card)), findsOneWidget);
      expect(enTarjeta(find.byType(EncabezadoReporte)), findsOneWidget);
      expect(enTarjeta(find.text('Parque Kennedy')), findsOneWidget);
      expect(
        find.descendant(
          of: enTarjeta(find.byType(SeccionSaturacion)),
          matching: find.text('Saturación reportada'),
        ),
        findsOneWidget,
      );
      expect(enTarjeta(find.text('Saturado')), findsOneWidget);
      expect(
        find.descendant(
          of: enTarjeta(find.byType(SeccionConfiabilidad)),
          matching: find.text('Confiabilidad del reporte'),
        ),
        findsOneWidget,
      );
      expect(find.text('CONFIABILIDAD DEL REPORTE'), findsNothing);
    });

    testWidgets('the validation chip sits beside the place name in the card', (
      tester,
    ) async {
      await abrir(tester, 101);

      final encabezado = enTarjeta(find.byType(EncabezadoReporte));
      expect(
        find.descendant(
          of: encabezado,
          matching: find.byType(ChipEstadoValidacion),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: encabezado, matching: find.text('Validado')),
        findsOneWidget,
      );
    });

    testWidgets('the helper and the vote breakdown sit in the reliability '
        'section, one compact line', (tester) async {
      await abrir(tester, 101);

      final seccion = enTarjeta(find.byType(SeccionConfiabilidad));
      expect(
        find.descendant(
          of: seccion,
          matching: find.text('Basado en confirmaciones de la comunidad'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: seccion,
          matching: find.text('18 confirman · 3 rechazan'),
        ),
        findsOneWidget,
      );
      expect(find.text('18 confirman'), findsNothing);
      expect(find.text('3 rechazan'), findsNothing);
    });

    testWidgets('the vote buttons and the report link stay inside the card', (
      tester,
    ) async {
      await abrir(tester, 101);

      expect(enTarjeta(find.text('Rechazar')), findsOneWidget);
      expect(enTarjeta(find.text('Confirmar')), findsOneWidget);
      expect(
        enTarjeta(find.text('Denunciar reporte fraudulento')),
        findsOneWidget,
      );
    });
  });

  group('S25 the author tier on the detail', () {
    /// [f] inside the "Reportado por" row.
    Finder enFila(Finder f) =>
        find.descendant(of: find.byType(FilaAutor), matching: f);

    testWidgets('"Reportado por" shows the author tier badge and name right '
        'under the header, like the Validar card', (tester) async {
      await abrir(tester, 101);

      expect(
        find.descendant(
          of: find.byType(EncabezadoReporte),
          matching: find.byType(FilaAutor),
        ),
        findsOneWidget,
      );
      expect(enFila(find.text('Reportado por')), findsOneWidget);
      expect(enFila(find.text('Crowd Collaborator')), findsOneWidget);
      expect(
        enFila(_insigniaTier('assets/images/tier_crowd_collaborator.png')),
        findsOneWidget,
      );
      final fila = tester.getTopLeft(find.text('Reportado por')).dy;
      expect(
        fila,
        greaterThan(tester.getTopLeft(find.text('Parque Kennedy')).dy),
      );
      expect(
        fila,
        lessThan(tester.getTopLeft(find.text('Saturación reportada')).dy),
      );
    });

    for (final (caso, autor) in [
      ('no autor (older backend)', null),
      ('an unknown tier', autorJson(tier: 'CROWD_LEGEND')),
    ]) {
      testWidgets('with $caso the row is hidden, never Crowd Baby', (
        tester,
      ) async {
        repo = _RepoConDetalle(
          DetalleReporte.fromJson(detalleJson(autor: autor)),
        );
        await abrir(tester, 31);

        expect(find.text('Parque Kennedy'), findsOneWidget);
        expect(find.byType(FilaAutor), findsNothing);
        expect(find.text('Reportado por'), findsNothing);
        expect(find.textContaining('Crowd '), findsNothing);
        expect(_insigniaTier(), findsNothing);
      });
    }
  });

  testWidgets('BAJA warns to take the report with caution', (tester) async {
    await abrir(tester, 104);

    expect(find.text('38%'), findsOneWidget);
    expect(find.text('Confiabilidad Baja'), findsOneWidget);
    expect(
      find.text(
        'Este reporte tiene pocas confirmaciones. Tómalo con precaución.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('INSUFICIENTE says there is not enough information', (
    tester,
  ) async {
    await abrir(tester, 102);

    expect(
      find.text(
        'Aún no hay información suficiente para determinar la confiabilidad.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('S15 voting thanks without points and then shows my vote', (
    tester,
  ) async {
    await abrir(tester, 101);

    await tester.tap(find.text('Rechazar'));
    await tester.pumpAndSettle();

    expect(find.text('¡Gracias por validar!'), findsOneWidget);
    expect(
      find.textContaining(RegExp(r'\+\d|puntos|karma', caseSensitive: false)),
      findsNothing,
    );
    expect(find.text('Tu voto: Rechazaste este reporte'), findsOneWidget);
    expect(find.text('Confirmar'), findsNothing);
    expect(find.text('18 confirman · 4 rechazan'), findsOneWidget);
  });

  testWidgets('S23 the thanks alert shows the voter tier beside it (C7)', (
    tester,
  ) async {
    await abrir(tester, 101);

    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(_enAviso(find.text('¡Gracias por validar!')), findsOneWidget);
    expect(_enAviso(find.text('Crowd Explorer')), findsOneWidget);
    expect(
      _enAviso(_insigniaTier('assets/images/tier_crowd_explorer.png')),
      findsOneWidget,
    );
    expect(find.text('Tu voto: Confirmaste este reporte'), findsOneWidget);
  });

  testWidgets('S23 with no tier in the response the alert is the message '
      'alone', (tester) async {
    repo = _RepoSinTier();
    await abrir(tester, 101);

    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(_enAviso(find.text('¡Gracias por validar!')), findsOneWidget);
    // The author row (S25) may show a tier; the alert itself must not.
    expect(_enAviso(find.textContaining('Crowd ')), findsNothing);
    expect(_enAviso(_insigniaTier()), findsNothing);
    expect(find.text('Tu voto: Confirmaste este reporte'), findsOneWidget);
  });

  testWidgets('an already voted report shows my vote on a later visit', (
    tester,
  ) async {
    await repo.validar(101, TipoAccionValidacion.confirmar);
    await abrir(tester, 101);

    expect(find.text('Tu voto: Confirmaste este reporte'), findsOneWidget);
  });

  testWidgets('my own report offers neither voting nor reporting', (
    tester,
  ) async {
    await abrir(tester, ValidacionRepositoryFake.idReportePropio);

    expect(find.text('Confirmar'), findsNothing);
    expect(find.text('Denunciar reporte fraudulento'), findsNothing);
  });

  testWidgets(
    'reporting: needs a motivo, then confirms and marks it reported',
    (tester) async {
      await abrir(tester, 101);

      await tester.tap(find.text('Denunciar reporte fraudulento'));
      await tester.pumpAndSettle();
      expect(find.text('¿Por qué lo denuncias?'), findsOneWidget);
      expect(
        find.text('Tu denuncia será revisada por el equipo de moderación.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Enviar denuncia'));
      await tester.pumpAndSettle();
      expect(
        find.text('Selecciona un motivo para enviar tu denuncia.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Spam o repetido'));
      await tester.tap(find.text('Enviar denuncia'));
      await tester.pumpAndSettle();
      expect(find.text('Denuncia enviada'), findsOneWidget);
      expect(
        find.text(
          'Gracias por avisar. El equipo de moderación revisará este reporte.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Listo'));
      await tester.pumpAndSettle();
      expect(find.text('Ya denunciaste este reporte'), findsOneWidget);
      expect(find.text('Denunciar reporte fraudulento'), findsNothing);
    },
  );

  testWidgets('a report that does not exist shows the error', (tester) async {
    await abrir(tester, 9999);

    expect(find.text('Reporte no encontrado'), findsOneWidget);
  });
}
