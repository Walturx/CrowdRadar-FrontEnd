import 'package:crowdradar/layout/admin_layout.dart';
import 'package:crowdradar/layout/cr_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'golden_harness.dart';

/// Labelled stand-in for a tab's screen: these captures are about the bar,
/// and each real screen has its own golden file.
Widget _tab(String name) => Scaffold(
  appBar: AppBar(title: Text(name)),
  body: Center(child: Text('Tab placeholder: $name')),
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
            // Golden captures stop at the nearest RepaintBoundary, so the bar
            // gets its own to crop the image to it.
            bottomNavigationBar: RepaintBoundary(
              child: CrBottomNav(
                currentIndex: index,
                onTap: (_) {},
                alertasNoLeidas: 3,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The tab bodies are stand-ins, so only the bar is captured.
      await matchBaselineOf(
        find.byType(CrBottomNav),
        'nav_principal_${name.toLowerCase()}',
      );
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
      // AdminLayout owns its NavigationBar, so this capture is the full
      // screen; the tab body is a labelled stand-in, not a real page.
      await matchBaseline('nav_admin_${name.toLowerCase()}');
    });
  }
}
