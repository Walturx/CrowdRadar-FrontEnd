import 'package:crowdradar/core/models/usuario.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/features/perfil/data/perfil_repository.dart';
import 'package:crowdradar/features/perfil/editar/edit_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../fakes/enrutador_falso.dart';

class _PerfilRepoMock extends Mock implements PerfilRepository {}

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
  setUp(() => repo = _PerfilRepoMock());

  /// Opens the edit page on top of `/inicio`, so `pop` has somewhere to go.
  Future<void> abrir(WidgetTester tester) async {
    final router = enrutadorDe(
      ruta: '/editar',
      pantalla: const EditProfilePage(user: _usuario),
    );
    await tester.pumpWidget(
      RepositoryProvider<PerfilRepository>.value(
        value: repo,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.push('/editar');
    await tester.pumpAndSettle();
  }

  Future<void> guardar(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.tap(find.text('Guardar cambios'));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('a failed save shows the error message in a snackbar', (
    tester,
  ) async {
    when(() => repo.actualizar(any())).thenThrow(
      const ApiException(status: 422, message: 'Teléfono inválido'),
    );
    await abrir(tester);

    await guardar(tester);

    expect(find.text('Teléfono inválido'), findsOneWidget);
    expect(find.text('Editar perfil'), findsOneWidget);
  });

  testWidgets('a successful save sends the edited fields and goes back', (
    tester,
  ) async {
    when(() => repo.actualizar(any())).thenAnswer((_) async => _usuario);
    await abrir(tester);

    await guardar(tester);
    await tester.pumpAndSettle();

    verify(
      () => repo.actualizar({
        'nombre': 'Ana',
        'apellido': 'Paz',
        'telefono': '999999999',
        'distrito': 'Miraflores',
      }),
    ).called(1);
    expect(find.text('RUTA /inicio'), findsOneWidget);
    expect(find.text('Perfil actualizado correctamente'), findsOneWidget);
  });
}
