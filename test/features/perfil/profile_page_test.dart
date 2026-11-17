import 'package:bloc_test/bloc_test.dart';
import 'package:crowdradar/core/models/tier_usuario.dart';
import 'package:crowdradar/core/models/usuario.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/session/sesion_cubit.dart';
import 'package:crowdradar/core/session/sesion_state.dart';
import 'package:crowdradar/features/perfil/data/perfil_repository.dart';
import 'package:crowdradar/features/perfil/ver/profile_page.dart';
import 'package:crowdradar/features/perfil/widgets/tarjeta_tier.dart';
import 'package:crowdradar/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../fakes/enrutador_falso.dart';

class _PerfilRepoMock extends Mock implements PerfilRepository {}

class _SesionCubitMock extends MockCubit<SesionState> implements SesionCubit {}

const _usuario = Usuario(
  id: 1,
  nombre: 'Ana',
  apellido: 'Paz',
  email: 'ana@test.com',
  telefono: '999999999',
  distrito: 'Miraflores',
);

/// The tier card, by key instead of by its (collision-prone) text.
Finder tarjetaTier() => find.byKey(TarjetaTier.clave);

/// Text [texto] inside the tier card.
Finder enTarjeta(String texto) =>
    find.descendant(of: tarjetaTier(), matching: find.text(texto));

/// The badge image [ruta] inside the tier card.
Finder insignia(String ruta) => find.descendant(
  of: tarjetaTier(),
  matching: find.byWidgetPredicate(
    (w) =>
        w is Image &&
        w.image is AssetImage &&
        (w.image as AssetImage).assetName == ruta,
  ),
);

void main() {
  late _PerfilRepoMock repo;
  late _SesionCubitMock sesion;

  setUp(() {
    repo = _PerfilRepoMock();
    sesion = _SesionCubitMock();
    when(() => sesion.cerrarSesion()).thenAnswer((_) async {});
  });

  Future<void> abrir(
    WidgetTester tester, {
    Widget pantalla = const ProfilePage(),
    List<String> otras = const ['/mapa', '/inicio'],
  }) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      RepositoryProvider<PerfilRepository>.value(
        value: repo,
        child: BlocProvider<SesionCubit>.value(
          value: sesion,
          child: MaterialApp.router(
            routerConfig: enrutadorDe(
              ruta: '/perfil',
              inicial: '/perfil',
              pantalla: pantalla,
              otras: otras,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('a load failure shows the message and a Reintentar button', (
    tester,
  ) async {
    when(
      () => repo.obtener(),
    ).thenThrow(const ApiException(status: 500, message: 'Servidor caído'));
    await abrir(tester);

    expect(find.text('Servidor caído'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('Reintentar loads the profile again', (tester) async {
    var llamadas = 0;
    when(() => repo.obtener()).thenAnswer((_) async {
      llamadas++;
      if (llamadas == 1) throw const ApiException.sinConexion();
      return _usuario;
    });
    await abrir(tester);

    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    await tester.pump();

    expect(llamadas, 2);
    expect(find.text('Ana Paz'), findsOneWidget);
    expect(find.text('Reintentar'), findsNothing);
  });

  group('Cerrar sesión (HU 2.4)', () {
    Future<void> tocarCerrar(WidgetTester tester) async {
      when(() => repo.obtener()).thenAnswer((_) async => _usuario);
      await abrir(tester);
      await tester.ensureVisible(find.text('Cerrar sesión'));
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
    }

    testWidgets('asks for confirmation before signing out', (tester) async {
      await tocarCerrar(tester);

      expect(find.text('¿Cerrar sesión?'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      verifyNever(() => sesion.cerrarSesion());
    });

    testWidgets('Cancelar keeps the session', (tester) async {
      await tocarCerrar(tester);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('¿Cerrar sesión?'), findsNothing);
      verifyNever(() => sesion.cerrarSesion());
    });

    testWidgets('confirming calls SesionCubit.cerrarSesion', (tester) async {
      await tocarCerrar(tester);

      await tester.tap(
        find.byKey(const ValueKey('confirmar-accion-confirmar')),
      );
      await tester.pumpAndSettle();

      verify(() => sesion.cerrarSesion()).called(1);
    });
  });

  group('redesign (CRO-88 T8-G4)', () {
    final acciones = find.byKey(const ValueKey('perfil-acciones'));
    final info = find.byKey(const ValueKey('perfil-info'));

    /// Height of the tappable area that holds [texto].
    double altoTocable(WidgetTester tester, Finder texto) => tester
        .getSize(find.ancestor(of: texto, matching: find.byType(InkWell)).first)
        .height;

    testWidgets('the header shows a 52 px initials avatar, no blue band', (
      tester,
    ) async {
      when(() => repo.obtener()).thenAnswer((_) async => _usuario);
      await abrir(tester);

      final avatar = find.byKey(const ValueKey('perfil-avatar'));
      expect(tester.getSize(avatar), const Size(52, 52));
      expect(
        find.descendant(of: avatar, matching: find.text('AP')),
        findsOneWidget,
      );
      expect(find.text('Ana Paz'), findsOneWidget);
      expect(find.text('ana@test.com'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is Container && w.color == AppColors.primary,
        ),
        findsNothing,
      );
    });

    testWidgets('the info grid lays the cards in two columns', (tester) async {
      when(() => repo.obtener()).thenAnswer(
        (_) async => _usuario.copyWith(rol: 'USUARIO', status: 'ACTIVO'),
      );
      await abrir(tester);

      for (final texto in [
        'Teléfono',
        '999999999',
        'Distrito',
        'Miraflores',
        'Rol',
        'USUARIO',
        'Estado',
        'ACTIVO',
      ]) {
        expect(
          find.descendant(of: info, matching: find.text(texto)),
          findsOneWidget,
        );
      }
      expect(
        tester.getTopLeft(find.text('Teléfono')).dy,
        tester.getTopLeft(find.text('Distrito')).dy,
      );
      expect(
        tester.getTopLeft(find.text('Rol')).dy,
        tester.getTopLeft(find.text('Estado')).dy,
      );
    });

    testWidgets('Estado keeps its text with the account status dot', (
      tester,
    ) async {
      when(
        () => repo.obtener(),
      ).thenAnswer((_) async => _usuario.copyWith(status: 'ACTIVO'));
      await abrir(tester);

      expect(
        find.descendant(
          of: info,
          matching: find.byKey(const ValueKey('punto-estado-cuenta')),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the actions are rows of one card, each at least 56 high', (
      tester,
    ) async {
      when(() => repo.obtener()).thenAnswer((_) async => _usuario);
      await abrir(tester);

      for (final texto in [
        'Editar perfil',
        'Mis reportes',
        'Cambiar contraseña',
        'Acerca de',
      ]) {
        final fila = find.descendant(of: acciones, matching: find.text(texto));
        expect(fila, findsOneWidget);
        expect(altoTocable(tester, fila), greaterThanOrEqualTo(56));
      }
    });

    testWidgets('Cerrar sesión is its own danger row', (tester) async {
      when(() => repo.obtener()).thenAnswer((_) async => _usuario);
      await abrir(tester);

      final cerrar = find.text('Cerrar sesión');
      expect(find.descendant(of: acciones, matching: cerrar), findsNothing);
      expect(tester.widget<Text>(cerrar).style?.color, AppColors.danger);
      expect(altoTocable(tester, cerrar), greaterThanOrEqualTo(56));
    });
  });

  testWidgets('Acerca de opens /perfil/acerca (R8)', (tester) async {
    when(() => repo.obtener()).thenAnswer((_) async => _usuario);
    await abrir(tester, otras: const ['/perfil/acerca']);

    await tester.ensureVisible(find.text('Acerca de'));
    await tester.tap(find.text('Acerca de'));
    await tester.pumpAndSettle();

    expect(find.text('RUTA /perfil/acerca'), findsOneWidget);
  });

  group('tier and reports (CRO-74 / HU 4.3)', () {
    for (final (tier, nombre, ruta) in [
      (
        TierUsuario.crowdBaby,
        'Crowd Baby',
        'assets/images/tier_crowd_baby.png',
      ),
      (
        TierUsuario.crowdExplorer,
        'Crowd Explorer',
        'assets/images/tier_crowd_explorer.png',
      ),
      (
        TierUsuario.crowdCollaborator,
        'Crowd Collaborator',
        'assets/images/tier_crowd_collaborator.png',
      ),
      (
        TierUsuario.crowdRoyalty,
        'Crowd Royalty',
        'assets/images/tier_crowd_royalty.png',
      ),
    ]) {
      testWidgets('S13/S20 shows the $nombre name and badge', (tester) async {
        when(
          () => repo.obtener(),
        ).thenAnswer((_) async => _usuario.copyWith(puntos: 77, tier: tier));
        await abrir(tester);

        expect(tarjetaTier(), findsOneWidget);
        expect(enTarjeta(nombre), findsOneWidget);
        expect(insignia(ruta), findsOneWidget);
      });
    }

    testWidgets('D5 shows the points but no karma', (tester) async {
      when(() => repo.obtener()).thenAnswer(
        (_) async =>
            _usuario.copyWith(puntos: 1280, tier: TierUsuario.crowdRoyalty),
      );
      await abrir(tester);

      expect(
        find.textContaining(RegExp('karma', caseSensitive: false)),
        findsNothing,
      );
      expect(enTarjeta('1280'), findsOneWidget);
      expect(enTarjeta('puntos'), findsOneWidget);
    });

    testWidgets('a user without tier data shows Crowd Baby', (tester) async {
      when(() => repo.obtener()).thenAnswer((_) async => _usuario);
      await abrir(tester);

      expect(enTarjeta('Crowd Baby'), findsOneWidget);
      expect(insignia('assets/images/tier_crowd_baby.png'), findsOneWidget);
    });

    testWidgets('Cambiar contraseña opens /perfil/password (HU 2.3 c1)', (
      tester,
    ) async {
      when(() => repo.obtener()).thenAnswer((_) async => _usuario);
      await abrir(tester, otras: const ['/perfil/password']);

      await tester.ensureVisible(find.text('Cambiar contraseña'));
      await tester.tap(find.text('Cambiar contraseña'));
      await tester.pumpAndSettle();

      expect(find.text('RUTA /perfil/password'), findsOneWidget);
    });

    testWidgets('Mis reportes opens /perfil/reportes', (tester) async {
      when(() => repo.obtener()).thenAnswer((_) async => _usuario);
      await abrir(tester, otras: const ['/perfil/reportes']);

      await tester.ensureVisible(find.text('Mis reportes'));
      await tester.tap(find.text('Mis reportes'));
      await tester.pumpAndSettle();

      expect(find.text('RUTA /perfil/reportes'), findsOneWidget);
    });

    testWidgets('reloads when its tab becomes active again', (tester) async {
      var tier = TierUsuario.crowdBaby;
      when(
        () => repo.obtener(),
      ).thenAnswer((_) async => _usuario.copyWith(tier: tier));
      final activa = ValueNotifier(true);
      await abrir(
        tester,
        pantalla: ValueListenableBuilder<bool>(
          valueListenable: activa,
          builder: (_, v, _) =>
              TickerMode(enabled: v, child: const ProfilePage()),
        ),
      );
      expect(enTarjeta('Crowd Baby'), findsOneWidget);

      activa.value = false;
      await tester.pump();
      tier = TierUsuario.crowdExplorer;
      activa.value = true;
      await tester.pump();
      await tester.pump();

      expect(enTarjeta('Crowd Explorer'), findsOneWidget);
      verify(() => repo.obtener()).called(2);
    });

    for (final (nombre, error) in [
      (
        'a server failure',
        const ApiException(status: 500, message: 'Servidor caído'),
      ),
      ('being offline', const ApiException.sinConexion()),
    ]) {
      testWidgets('$nombre on re-activation keeps the profile on screen', (
        tester,
      ) async {
        var falla = false;
        when(() => repo.obtener()).thenAnswer((_) async {
          if (falla) throw error;
          return _usuario.copyWith(tier: TierUsuario.crowdCollaborator);
        });
        final activa = ValueNotifier(true);
        await abrir(
          tester,
          pantalla: ValueListenableBuilder<bool>(
            valueListenable: activa,
            builder: (_, v, _) =>
                TickerMode(enabled: v, child: const ProfilePage()),
          ),
        );

        activa.value = false;
        await tester.pump();
        falla = true;
        activa.value = true;
        await tester.pump();
        await tester.pump();

        expect(enTarjeta('Crowd Collaborator'), findsOneWidget);
        expect(find.text('Reintentar'), findsNothing);
        expect(find.text(error.message), findsOneWidget);
      });
    }
  });
}
