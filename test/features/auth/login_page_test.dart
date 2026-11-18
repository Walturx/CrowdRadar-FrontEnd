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

  Future<void> abrir(WidgetTester tester, {double escalaTexto = 1.0}) async {
    await tester.pumpWidget(
      RepositoryProvider<AuthRepository>.value(
        value: repo,
        child: MaterialApp.router(
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(escalaTexto)),
              child: child!,
            );
          },
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
    await tester.tap(find.byKey(const Key('boton-iniciar-sesion')));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('a failed login shows the error message in a banner above '
      'the form, not in a snackbar', (tester) async {
    when(() => repo.iniciarSesion(any(), any())).thenThrow(
      const ApiException(status: 401, message: 'Credenciales inválidas'),
    );
    await abrir(tester);

    await enviar(tester);

    final aviso = find.byKey(const ValueKey('aviso-error-login'));
    expect(aviso, findsOneWidget);
    expect(
      find.descendant(of: aviso, matching: find.text('Credenciales inválidas')),
      findsOneWidget,
    );
    expect(find.text('Credenciales inválidas'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('RUTA /mapa'), findsNothing);
    // The banner sits above the form.
    expect(
      tester.getRect(aviso).bottom,
      lessThanOrEqualTo(tester.getRect(find.byType(TextFormField).at(0)).top),
    );
  });

  testWidgets('a failed login keeps what the user typed in the fields', (
    tester,
  ) async {
    when(() => repo.iniciarSesion(any(), any())).thenThrow(
      const ApiException(status: 401, message: 'Credenciales inválidas'),
    );
    await abrir(tester);

    await enviar(tester);

    expect(find.text('ana@test.com'), findsOneWidget);
  });

  testWidgets('no error banner is shown before any attempt', (tester) async {
    await abrir(tester);

    expect(find.byKey(const ValueKey('aviso-error-login')), findsNothing);
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

    final boton = find.byKey(const Key('boton-iniciar-sesion'));
    bool habilitado() =>
        isSemantics(isEnabled: true).matches(tester.getSemantics(boton), {});
    expect(
      find.text('Demasiados intentos, prueba en 1 minuto'),
      findsOneWidget,
    );
    expect(find.text('Iniciar sesión (3s)'), findsOneWidget);
    expect(habilitado(), isFalse);

    await tester.pump(const Duration(seconds: 3));

    expect(find.text('Iniciar sesión (3s)'), findsNothing);
    expect(habilitado(), isTrue);
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

    await tester.tap(find.byKey(const Key('boton-iniciar-sesion')));
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

  group('CRO-85: usabilidad y accesibilidad', () {
    testWidgets('ACC-APP-01: el login soporta texto ampliado al 130%', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(412, 915);
      addTearDown(tester.view.reset);

      await abrir(tester, escalaTexto: 1.3);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      expect(find.byType(TextFormField), findsNWidgets(2));

      final boton = find.byKey(const Key('boton-iniciar-sesion'));

      await tester.ensureVisible(boton);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(boton.hitTestable(), findsOneWidget);
    });

    testWidgets('ACC-APP-02: los campos de acceso tienen etiquetas', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await abrir(tester);

      expect(find.byType(TextFormField), findsNWidgets(2));

      const etiquetas = {
        'campo-correo-login': 'Correo electrónico',
        'campo-contrasena-login': 'Contraseña',
      };
      for (final MapEntry(key: clave, value: etiqueta) in etiquetas.entries) {
        final campo = find.byKey(Key(clave));
        final texto = find.text(etiqueta);
        expect(campo, findsOneWidget);
        // The label is always visible, above its field.
        expect(texto, findsOneWidget, reason: 'Falta la etiqueta $etiqueta');
        expect(
          tester.getRect(texto).bottom,
          lessThanOrEqualTo(tester.getRect(campo).top),
          reason: 'La etiqueta $etiqueta debe ir arriba del campo',
        );
        // Screen readers still announce the label with the field.
        expect(
          tester.getSemantics(find.byKey(Key(clave))),
          isSemantics(label: etiqueta, isTextField: true),
        );
      }
      semantica.dispose();
    });

    testWidgets('ACC-APP-03: el boton de login tiene un area tactil adecuada', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(412, 915);
      addTearDown(tester.view.reset);

      await abrir(tester);

      final boton = find.byKey(const Key('boton-iniciar-sesion'));

      expect(boton, findsOneWidget);

      await tester.ensureVisible(boton);
      await tester.pumpAndSettle();

      final tamano = tester.getSize(boton);

      expect(
        tamano.width,
        greaterThanOrEqualTo(48),
        reason: 'El boton debe tener al menos 48 px de ancho',
      );

      expect(
        tamano.height,
        greaterThanOrEqualTo(48),
        reason: 'El boton debe tener al menos 48 px de alto',
      );

      expect(boton.hitTestable(), findsOneWidget);
    });

    testWidgets('S5: el boton y los enlaces miden al menos 44 x 44', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(412, 915);
      addTearDown(tester.view.reset);
      await abrir(tester);

      for (final clave in const [
        'boton-iniciar-sesion',
        'enlace-olvidaste-contrasena',
        'enlace-registrate',
      ]) {
        final objetivo = find.byKey(Key(clave));
        expect(objetivo, findsOneWidget, reason: clave);
        final tamano = tester.getSize(objetivo);
        expect(tamano.width, greaterThanOrEqualTo(44), reason: clave);
        expect(tamano.height, greaterThanOrEqualTo(44), reason: clave);
      }
      expect(
        find.descendant(
          of: find.byKey(const Key('enlace-olvidaste-contrasena')),
          matching: find.text('¿Olvidaste tu contraseña?'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('enlace-registrate')),
          matching: find.textContaining('Regístrate', findRichText: true),
        ),
        findsOneWidget,
      );
    });

    testWidgets('muestra el subtitulo explicativo bajo el titulo', (
      tester,
    ) async {
      await abrir(tester);

      expect(
        find.text('Mira qué tan lleno está un lugar antes de salir.'),
        findsOneWidget,
      );
    });
  });
}
