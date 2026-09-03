import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'cr_bottom_nav.dart';

/// Shell with the bottom navigation (Mapa, Validar, Favoritos, Perfil).
class MainLayout extends StatelessWidget {
  final StatefulNavigationShell shell;

  const MainLayout({super.key, required this.shell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: CrBottomNav(
        currentIndex: shell.currentIndex,
        onTap: (index) => shell.goBranch(
          index,
          initialLocation: index == shell.currentIndex,
        ),
      ),
    );
  }
}
