import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/features/auth/data/auth_repository.dart';
import 'package:crowdradar/features/auth/recuperar/recuperar_cubit.dart';
import 'package:crowdradar/features/auth/recuperar/recuperar_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fakes/enrutador_falso.dart';

class _AuthRepoMock extends Mock implements AuthRepository {}

void main() {
  late _AuthRepoMock repo;
  setUp(() => repo = _AuthRepoMock());

  Future<void> abrir(WidgetTester tester) => tester.pumpWidget(
    RepositoryProvider<AuthRepository>.value(
      value: repo,
      child: MaterialApp.router(
        routerConfig: enrutadorDe(
          ruta: '/recuperar',
          inicial: '/recuperar',
          pantalla: const RecuperarPage(),
        ),
      ),
    ),
  );

  Future<void> enviar(WidgetTester tester, String correo) async {
    await tester.enterText(find.byType(TextFormField), correo);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Enviar enlace'));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('HU 2.1 c1 asks for the email', (tester) async {
    await abrir(tester);

    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(
      find.widgetWithText(ElevatedButton, 'Enviar enlace'),
      findsOneWidget,
    );
  });

  testWidgets('HU 2.1 c2 shows the neutral message and hides the form', (
    tester,
  ) async {
    when(
      () => repo.solicitarRecuperacion('ana@test.com'),
    ).thenAnswer((_) async {});
    await abrir(tester);

    await enviar(tester, 'ana@test.com');

    expect(find.text(RecuperarCubit.mensajeNeutral), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Volver a iniciar sesión'), findsOneWidget);
  });

  testWidgets('HU 2.1 c3 shows the not-registered message', (tester) async {
    when(() => repo.solicitarRecuperacion(any())).thenThrow(
      const ApiException(status: 404, message: 'x', code: 'CUENTA_NO_EXISTE'),
    );
    await abrir(tester);

    await enviar(tester, 'ana@test.com');

    expect(find.text('Ese correo no está registrado'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
  });

  testWidgets('an invalid email never reaches the repository', (tester) async {
    await abrir(tester);

    await enviar(tester, 'sin-arroba');

    verifyNever(() => repo.solicitarRecuperacion(any()));
    expect(find.text('Ingresá un correo válido'), findsOneWidget);
  });

  testWidgets('"Volver a iniciar sesión" goes back to the login', (
    tester,
  ) async {
    when(() => repo.solicitarRecuperacion(any())).thenAnswer((_) async {});
    await tester.pumpWidget(
      RepositoryProvider<AuthRepository>.value(
        value: repo,
        child: MaterialApp.router(
          routerConfig: enrutadorDe(
            ruta: '/recuperar',
            inicial: '/recuperar',
            pantalla: const RecuperarPage(),
            otras: const ['/login'],
          ),
        ),
      ),
    );
    await enviar(tester, 'ana@test.com');

    await tester.tap(find.text('Volver a iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('RUTA /login'), findsOneWidget);
  });
}
