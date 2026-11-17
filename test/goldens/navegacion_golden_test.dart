import 'package:crowdradar/layout/admin_layout.dart';
import 'package:crowdradar/layout/cr_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'golden_harness.dart';

/// Plain stand-in for a tab's screen, so the image is about the bar.
Widget _tab(String name) => Scaffold(
  appBar: AppBar(title: Text(name)),
  body: const SizedBox.expand(),
);

void main() {
  const mainTabs = ['Mapa', 'Validar', 'Favoritos', 'Perfil'];

  for (final (index, name) in mainTabs.indexed) {
    testWidgets('bottom nav, main, $name selected, 3 unread alerts', (
      tester,
    ) async {
      usePhoneSurface(tester);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: appTheme,
          builder: withoutAnimations,
          home: Scaffold(
            body: _tab(name),
            bottomNavigationBar: CrBottomNav(
              currentIndex: index,
              onTap: (_) {},
              alertasNoLeidas: 3,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await matchBaseline('nav_principal_${name.toLowerCase()}');
    });
  }

  const adminTabs = ['Reportes', 'Usuarios'];

  for (final name in adminTabs) {
    testWidgets('bottom nav, admin, $name selected', (tester) async {
      usePhoneSurface(tester);
      final router = GoRouter(
        initialLocation: '/admin/${name.toLowerCase()}',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (_, _, shell) => AdminLayout(shell: shell),
            branches: [
              for (final tab in adminTabs)
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/admin/${tab.toLowerCase()}',
                      builder: (_, _) => _tab(tab),
                    ),
                  ],
                ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: appTheme,
          builder: withoutAnimations,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(name), findsWidgets);
      await matchBaseline('nav_admin_${name.toLowerCase()}');
    });
  }
}
