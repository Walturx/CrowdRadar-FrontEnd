import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/features/auth/data/auth_repository.dart';
import 'package:crowdradar/features/auth/login/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../fakes/enrutador_falso.dart';
import 'golden_harness.dart';

class _AuthRepoMock extends Mock implements AuthRepository {}

void main() {
  late _AuthRepoMock repo;
  setUp(() => repo = _AuthRepoMock());

  Future<void> open(WidgetTester tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(
      RepositoryProvider<AuthRepository>.value(
        value: repo,
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: appTheme,
          builder: withoutAnimations,
          routerConfig: enrutadorDe(
            ruta: '/login',
            inicial: '/login',
            pantalla: const LoginPage(),
          ),
        ),
      ),
    );
    await loadImages(tester);
  }

  testWidgets('login, empty form', (tester) async {
    await open(tester);

    await matchBaseline('login_empty');
  });

  testWidgets('login, API error', (tester) async {
    when(() => repo.iniciarSesion(any(), any())).thenThrow(
      const ApiException(status: 401, message: 'Credenciales inválidas'),
    );
    await open(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'ana@test.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'Secreta1');
    await clearFocus(tester);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Credenciales inválidas'), findsOneWidget);
    await matchBaseline('login_api_error');
  });
}
