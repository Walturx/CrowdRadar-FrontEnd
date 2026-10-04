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

  testWidgets('invalid input never reaches the repository', (tester) async {
    await abrir(tester);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar sesión'));
    await tester.pump();

    verifyNever(() => repo.iniciarSesion(any(), any()));
    expect(find.text('Ingresá tu correo'), findsOneWidget);
  });
}
