import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

/// Admin shell: tabs Reportes (denunciados) and Usuarios.
///
/// The bar follows the theme's `NavigationBarTheme` (white, `primaryContainer`
/// pill); here it only adds the top border line of design-system §5.
class AdminLayout extends StatelessWidget {
  final StatefulNavigationShell shell;

  const AdminLayout({super.key, required this.shell});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: shell,
    bottomNavigationBar: DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: NavigationBar(
        key: const ValueKey('nav-admin'),
        // Flat white bar: no elevation tint over the surface color.
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag),
            label: 'Reportes',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group),
            label: 'Usuarios',
          ),
        ],
      ),
    ),
  );
}
