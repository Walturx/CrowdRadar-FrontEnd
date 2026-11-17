import 'package:bloc_test/bloc_test.dart';
import 'package:crowdradar/core/models/tier_usuario.dart';
import 'package:crowdradar/core/models/usuario.dart';
import 'package:crowdradar/core/session/sesion_cubit.dart';
import 'package:crowdradar/core/session/sesion_state.dart';
import 'package:crowdradar/features/perfil/data/perfil_repository.dart';
import 'package:crowdradar/features/perfil/ver/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../fakes/enrutador_falso.dart';
import 'golden_harness.dart';

class _PerfilRepoMock extends Mock implements PerfilRepository {}

class _SesionCubitMock extends MockCubit<SesionState> implements SesionCubit {}

/// Points that sit inside each tier, so the card is coherent once it shows them.
const Map<TierUsuario, int> _points = {
  TierUsuario.crowdBaby: 15,
  TierUsuario.crowdExplorer: 120,
  TierUsuario.crowdCollaborator: 480,
  TierUsuario.crowdRoyalty: 1250,
};

void main() {
  Future<void> open(WidgetTester tester, TierUsuario tier) async {
    usePhoneSurface(tester);
    final repo = _PerfilRepoMock();
    when(() => repo.obtener()).thenAnswer(
      (_) async => Usuario(
        id: 1,
        nombre: 'Ana',
        apellido: 'Paz',
        email: 'ana@test.com',
        telefono: '999999999',
        distrito: 'Miraflores',
        puntos: _points[tier]!,
        tier: tier,
      ),
    );
    await tester.pumpWidget(
      RepositoryProvider<PerfilRepository>.value(
        value: repo,
        child: BlocProvider<SesionCubit>.value(
          value: _SesionCubitMock(),
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: appTheme,
            builder: withoutAnimations,
            routerConfig: enrutadorDe(
              ruta: '/perfil',
              inicial: '/perfil',
              pantalla: const ProfilePage(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await loadImages(tester);
  }

  testWidgets('profile, loaded, top of the screen', (tester) async {
    await open(tester, TierUsuario.crowdCollaborator);

    expect(find.text('Ana Paz'), findsOneWidget);
    await matchBaseline('perfil_cargado');
  });

  // The tier card sits below the fold: scroll to the end so each badge shows.
  for (final tier in TierUsuario.values) {
    testWidgets('profile, tier card, ${tier.name}', (tester) async {
      await open(tester, tier);

      // The list builds lazily, so the logout row only exists once scrolled.
      await tester.scrollUntilVisible(
        find.text('Cerrar sesión'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text(tier.nombre), findsOneWidget);
      await matchBaseline('perfil_tier_${tier.name}');
    });
  }
}
