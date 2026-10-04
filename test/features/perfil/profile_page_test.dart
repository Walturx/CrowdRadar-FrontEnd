import 'package:bloc_test/bloc_test.dart';
import 'package:crowdradar/core/models/usuario.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/session/sesion_cubit.dart';
import 'package:crowdradar/core/session/sesion_state.dart';
import 'package:crowdradar/features/perfil/data/perfil_repository.dart';
import 'package:crowdradar/features/perfil/ver/profile_page.dart';
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

/// The karma card, by key instead of by its (collision-prone) text.
Finder tarjetaKarma() => find.byKey(const Key('perfil-karma'));

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
    when(() => repo.obtener()).thenThrow(
      const ApiException(status: 500, message: 'Servidor caído'),
    );
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

  testWidgets('Cerrar sesión calls SesionCubit.cerrarSesion', (tester) async {
    when(() => repo.obtener()).thenAnswer((_) async => _usuario);
    await abrir(tester);

    await tester.ensureVisible(find.text('Cerrar sesión'));
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pump();

    verify(() => sesion.cerrarSesion()).called(1);
  });

  group('karma and reports (HU 4.2 / 4.3)', () {
    testWidgets('shows the accumulated karma points', (tester) async {
      when(() => repo.obtener())
          .thenAnswer((_) async => _usuario.copyWith(puntosKarma: 1280));
      await abrir(tester);

      expect(tarjetaKarma(), findsOneWidget);
      expect(
        find.descendant(of: tarjetaKarma(), matching: find.text('1280')),
        findsOneWidget,
      );
    });

    testWidgets('a user without karma data shows 0', (tester) async {
      when(() => repo.obtener()).thenAnswer((_) async => _usuario);
      await abrir(tester);

      expect(
        find.descendant(of: tarjetaKarma(), matching: find.text('0')),
        findsOneWidget,
      );
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
      var karma = 100;
      when(() => repo.obtener()).thenAnswer(
        (_) async => _usuario.copyWith(puntosKarma: karma),
      );
      final activa = ValueNotifier(true);
      await abrir(
        tester,
        pantalla: ValueListenableBuilder<bool>(
          valueListenable: activa,
          builder: (_, v, _) =>
              TickerMode(enabled: v, child: const ProfilePage()),
        ),
      );
      expect(
        find.descendant(of: tarjetaKarma(), matching: find.text('100')),
        findsOneWidget,
      );

      activa.value = false;
      await tester.pump();
      karma = 110;
      activa.value = true;
      await tester.pump();
      await tester.pump();

      expect(
        find.descendant(of: tarjetaKarma(), matching: find.text('110')),
        findsOneWidget,
      );
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
          return _usuario.copyWith(puntosKarma: 100);
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

        expect(
          find.descendant(of: tarjetaKarma(), matching: find.text('100')),
          findsOneWidget,
        );
        expect(find.text('Reintentar'), findsNothing);
        expect(find.text(error.message), findsOneWidget);
      });
    }
  });
}
