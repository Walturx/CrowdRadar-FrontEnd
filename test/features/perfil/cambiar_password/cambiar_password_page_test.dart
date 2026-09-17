import 'package:bloc_test/bloc_test.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/session/motivo_cierre.dart';
import 'package:crowdradar/core/session/sesion_cubit.dart';
import 'package:crowdradar/core/session/sesion_state.dart';
import 'package:crowdradar/features/perfil/cambiar_password/cambiar_password_cubit.dart';
import 'package:crowdradar/features/perfil/cambiar_password/cambiar_password_page.dart';
import 'package:crowdradar/features/perfil/data/perfil_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fakes/enrutador_falso.dart';

class _PerfilRepoMock extends Mock implements PerfilRepository {}

class _SesionCubitMock extends MockCubit<SesionState> implements SesionCubit {}

void main() {
  setUpAll(() => registerFallbackValue(MotivoCierre.usuario));

  late _PerfilRepoMock repo;
  late _SesionCubitMock sesion;

  setUp(() {
    repo = _PerfilRepoMock();
    sesion = _SesionCubitMock();
    when(
      () => sesion.cerrarSesion(motivo: any(named: 'motivo')),
    ).thenAnswer((_) async {});
  });

  Future<void> abrir(WidgetTester tester) async {
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
              ruta: '/perfil/password',
              inicial: '/perfil/password',
              pantalla: const CambiarPasswordPage(),
            ),
          ),
        ),
      ),
    );
  }

  Finder campo(String clave) => find.byKey(Key(clave));

  Future<void> llenar(
    WidgetTester tester, {
    String actual = 'Vieja123',
    String nueva = 'Nueva1234',
    String confirmar = 'Nueva1234',
  }) async {
    await tester.enterText(campo('campo-password-actual'), actual);
    await tester.enterText(campo('campo-password-nueva'), nueva);
    await tester.enterText(campo('campo-password-confirmar'), confirmar);
  }

  Future<void> enviar(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(ElevatedButton, 'Cambiar contraseña'));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('HU 2.3 c1 shows the three password fields', (tester) async {
    await abrir(tester);

    expect(campo('campo-password-actual'), findsOneWidget);
    expect(campo('campo-password-nueva'), findsOneWidget);
    expect(campo('campo-password-confirmar'), findsOneWidget);
  });

  testWidgets('the requirement list reacts to what is typed', (tester) async {
    await abrir(tester);
    expect(find.text('Al menos 8 caracteres'), findsOneWidget);

    await tester.enterText(campo('campo-password-nueva'), 'abc');
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsOneWidget); // only the maximum
    expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(3));

    await tester.enterText(campo('campo-password-nueva'), 'Secreta1');
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsNWidgets(4));
    expect(find.byIcon(Icons.radio_button_unchecked), findsNothing);
  });

  testWidgets('empty fields never reach the repository', (tester) async {
    await abrir(tester);

    await enviar(tester);

    verifyNever(
      () => repo.cambiarPassword(
        actual: any(named: 'actual'),
        nueva: any(named: 'nueva'),
        confirmar: any(named: 'confirmar'),
      ),
    );
    expect(find.text('Ingresá tu contraseña actual'), findsOneWidget);
  });

  testWidgets('a mismatch is reported without calling the repository', (
    tester,
  ) async {
    await abrir(tester);
    await llenar(tester, confirmar: 'Otra12345');

    await enviar(tester);

    expect(find.text('Las contraseñas no coinciden'), findsWidgets);
    verifyNever(
      () => repo.cambiarPassword(
        actual: any(named: 'actual'),
        nueva: any(named: 'nueva'),
        confirmar: any(named: 'confirmar'),
      ),
    );
  });

  testWidgets('HU 2.3 c3 a wrong current password shows the server message', (
    tester,
  ) async {
    when(
      () => repo.cambiarPassword(
        actual: any(named: 'actual'),
        nueva: any(named: 'nueva'),
        confirmar: any(named: 'confirmar'),
      ),
    ).thenThrow(
      const ApiException(
        status: 422,
        message: 'La contraseña actual es incorrecta',
        code: 'PASSWORD_ACTUAL_INCORRECTA',
      ),
    );
    await abrir(tester);
    await llenar(tester);

    await enviar(tester);

    expect(find.text('La contraseña actual es incorrecta'), findsOneWidget);
    verifyNever(() => sesion.cerrarSesion(motivo: any(named: 'motivo')));
  });

  testWidgets(
    'HU 2.3 c2 success shows the message and signs out with the password motive',
    (tester) async {
      when(
        () => repo.cambiarPassword(
          actual: 'Vieja123',
          nueva: 'Nueva1234',
          confirmar: 'Nueva1234',
        ),
      ).thenAnswer((_) async {});
      await abrir(tester);
      await llenar(tester);

      await enviar(tester);

      expect(find.text(CambiarPasswordCubit.mensajeExito), findsOneWidget);
      verify(
        () => sesion.cerrarSesion(motivo: MotivoCierre.passwordCambiada),
      ).called(1);
    },
  );
}
