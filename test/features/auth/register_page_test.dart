import 'package:crowdradar/core/models/usuario.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/features/auth/data/auth_repository.dart';
import 'package:crowdradar/features/auth/registro/register_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../fakes/enrutador_falso.dart';

class _AuthRepoMock extends Mock implements AuthRepository {}

void main() {
  late _AuthRepoMock repo;
  setUp(() => repo = _AuthRepoMock());

  /// Opens the page on top of `/inicio` so a successful `pop` is observable.
  Future<void> abrir(WidgetTester tester) async {
    final router = enrutadorDe(
      ruta: '/registro',
      pantalla: const RegisterPage(),
    );
    await tester.pumpWidget(
      RepositoryProvider<AuthRepository>.value(
        value: repo,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.push('/registro');
    await tester.pumpAndSettle();
  }

  When<Future<Usuario>> registrarLlamada() => when(
    () => repo.registrar(
      nombre: any(named: 'nombre'),
      apellido: any(named: 'apellido'),
      email: any(named: 'email'),
      password: any(named: 'password'),
      telefono: any(named: 'telefono'),
      distrito: any(named: 'distrito'),
    ),
  );

  Future<void> llenarYEnviar(WidgetTester tester) async {
    Future<void> escribir(String campo, String texto) =>
        tester.enterText(find.byKey(Key('campo-$campo')), texto);
    await escribir('nombre', 'Ana');
    await escribir('apellido', 'Paz');
    await escribir('email', 'ana@test.com');
    await escribir('password', 'Secreta12');
    await escribir('telefono', '999999999');
    await escribir('distrito', 'Miraflores');
    await tester.ensureVisible(find.text('Registrarme'));
    await tester.tap(find.text('Registrarme'));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('R3-103 a backend field error shows under its field', (
    tester,
  ) async {
    registrarLlamada().thenThrow(
      const ApiException(
        status: 400,
        message: 'Datos inválidos',
        errors: [ErrorCampo(campo: 'email', mensaje: 'Email ya registrado')],
      ),
    );
    await abrir(tester);

    await llenarYEnviar(tester);

    expect(
      find.descendant(
        of: find.byKey(const Key('campo-email')),
        matching: find.text('Email ya registrado'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('campo-nombre')),
        matching: find.text('Email ya registrado'),
      ),
      findsNothing,
    );
  });

  testWidgets('a failed registration shows the message in a snackbar', (
    tester,
  ) async {
    registrarLlamada().thenThrow(
      const ApiException(status: 409, message: 'El email ya está registrado'),
    );
    await abrir(tester);

    await llenarYEnviar(tester);

    expect(find.text('El email ya está registrado'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsOneWidget);
  });

  testWidgets('a successful registration confirms and goes back', (
    tester,
  ) async {
    registrarLlamada().thenAnswer((_) async => const Usuario(id: 2));
    await abrir(tester);

    await llenarYEnviar(tester);
    await tester.pumpAndSettle();

    expect(find.text('RUTA /inicio'), findsOneWidget);
    expect(find.text('Usuario registrado correctamente'), findsOneWidget);
  });
}
