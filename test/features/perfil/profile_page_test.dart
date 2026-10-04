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

void main() {
  late _PerfilRepoMock repo;
  late _SesionCubitMock sesion;

  setUp(() {
    repo = _PerfilRepoMock();
    sesion = _SesionCubitMock();
    when(() => sesion.cerrarSesion()).thenAnswer((_) async {});
  });

  Future<void> abrir(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      RepositoryProvider<PerfilRepository>.value(
        value: repo,
        child: BlocProvider<SesionCubit>.value(
          value: sesion,
          child: MaterialApp.router(
            routerConfig: enrutadorDe(
              ruta: '/perfil',
              inicial: '/perfil',
              pantalla: const ProfilePage(),
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
}
