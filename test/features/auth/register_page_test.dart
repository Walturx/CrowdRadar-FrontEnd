import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/features/auth/data/auth_repository.dart';
import 'package:crowdradar/features/auth/registro/register_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _AuthRepoMock extends Mock implements AuthRepository {}

void main() {
  late _AuthRepoMock repo;
  setUp(() => repo = _AuthRepoMock());

  Future<void> abrir(WidgetTester tester) async {
    await tester.pumpWidget(
      RepositoryProvider<AuthRepository>.value(
        value: repo,
        child: const MaterialApp(home: RegisterPage()),
      ),
    );
  }

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
    when(
      () => repo.registrar(
        nombre: any(named: 'nombre'),
        apellido: any(named: 'apellido'),
        email: any(named: 'email'),
        password: any(named: 'password'),
        telefono: any(named: 'telefono'),
        distrito: any(named: 'distrito'),
      ),
    ).thenThrow(
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
}
