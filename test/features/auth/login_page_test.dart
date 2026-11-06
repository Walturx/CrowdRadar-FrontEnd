import 'package:crowdradar/core/models/usuario.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/features/auth/data/auth_repository.dart';
import 'package:crowdradar/features/auth/login/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../fakes/enrutador_falso.dart';

class _AuthRepoMock extends Mock implements AuthRepository {}

void main() {
  late _AuthRepoMock repo;
  setUp(() => repo = _AuthRepoMock());

  Future<void> abrir(WidgetTester tester) async {
    await tester.pumpWidget(
      RepositoryProvider<AuthRepository>.value(
        value: repo,
        child: MaterialApp.router(
          routerConfig: enrutadorDe(
            ruta: '/login',
            inicial: '/login',
            pantalla: const LoginPage(),
          ),
        ),
      ),
    );
  }

  Future<void> enviar(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField).at(0), 'ana@test.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'Secreta1');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar sesión'));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('a failed login shows the error message in a snackbar', (
    tester,
  ) async {
    when(() => repo.iniciarSesion(any(), any())).thenThrow(
      const ApiException(status: 401, message: 'Credenciales inválidas'),
    );
    await abrir(tester);

    await enviar(tester);

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Credenciales inválidas'), findsOneWidget);
    expect(find.text('RUTA /mapa'), findsNothing);
  });

  testWidgets('a 429 disables the button while the wait counts down', (
    tester,
  ) async {
    when(() => repo.iniciarSesion(any(), any())).thenThrow(
      const ApiException(
        status: 429,
        message: 'x',
        code: 'DEMASIADOS_INTENTOS',
        reintentarEnSegundos: 3,
      ),
    );
    await abrir(tester);

    await enviar(tester);

    final boton = find.descendant(
      of: find.byKey(const Key('boton-iniciar-sesion')),
      matching: find.byType(ElevatedButton),
    );
    expect(
      find.text('Demasiados intentos, prueba en 1 minuto'),
      findsOneWidget,
    );
    expect(find.text('Iniciar sesión (3s)'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(boton).enabled, isFalse);

    await tester.pump(const Duration(seconds: 3));

    expect(find.text('Iniciar sesión (3s)'), findsNothing);
    expect(tester.widget<ElevatedButton>(boton).enabled, isTrue);
  });

  group('S21 logo', () {
    Finder logo(String ruta) => find.byWidgetPredicate(
      (w) =>
          w is Image &&
          w.image is AssetImage &&
          (w.image as AssetImage).assetName == ruta,
    );

    testWidgets('shows the new logo with the wordmark, not the old one', (
      tester,
    ) async {
      await abrir(tester);

      expect(logo('assets/images/crowdradar-logo.png'), findsOneWidget);
      expect(
        logo('assets/images/crowdradar-logo-transparent.png'),
        findsNothing,
      );
      // The wordmark already names the app: no duplicated title.
      expect(find.text('CrowdRadar'), findsNothing);
    });

    testWidgets('fits a narrow phone without overflowing', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      addTearDown(tester.view.reset);
      await abrir(tester);

      expect(tester.takeException(), isNull);
      final caja = tester.getRect(logo('assets/images/crowdradar-logo.png'));
      expect(caja.left, greaterThanOrEqualTo(0));
      expect(caja.right, lessThanOrEqualTo(320));
    });
  });

  testWidgets('a successful login navigates to the map', (tester) async {
    when(
      () => repo.iniciarSesion('ana@test.com', 'Secreta1'),
    ).thenAnswer((_) async => const Usuario(id: 1, nombre: 'Ana'));
    await abrir(tester);

    await enviar(tester);
    await tester.pumpAndSettle();

    verify(() => repo.iniciarSesion('ana@test.com', 'Secreta1')).called(1);
    expect(find.text('RUTA /mapa'), findsOneWidget);
  });

  testWidgets('the form scrolls instead of overflowing behind the keyboard', (
    tester,
  ) async {
    // A phone-sized screen with the keyboard covering ~40 % of it.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    tester.view.viewInsets = const FakeViewPadding(bottom: 400);
    addTearDown(tester.view.reset);
    await abrir(tester);

    expect(tester.takeException(), isNull);
    final registrate = find.textContaining('¿No tienes cuenta?');
    await tester.ensureVisible(registrate);
    await tester.pumpAndSettle();
    expect(registrate.hitTestable(), findsOneWidget);
  });

  testWidgets('invalid input never reaches the repository', (tester) async {
    await abrir(tester);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar sesión'));
    await tester.pump();

    verifyNever(() => repo.iniciarSesion(any(), any()));
    expect(find.text('Ingresa tu correo'), findsOneWidget);
  });

  testWidgets('"¿Olvidaste tu contraseña?" opens the recovery screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      RepositoryProvider<AuthRepository>.value(
        value: repo,
        child: MaterialApp.router(
          routerConfig: enrutadorDe(
            ruta: '/login',
            inicial: '/login',
            pantalla: const LoginPage(),
            otras: const ['/recuperar'],
          ),
        ),
      ),
    );

    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await tester.pumpAndSettle();

    expect(find.text('RUTA /recuperar'), findsOneWidget);
  });
}
