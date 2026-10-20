import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Admin shell: tabs Reportes (denunciados) and Usuarios.
class AdminLayout extends StatelessWidget {
  final StatefulNavigationShell shell;

  const AdminLayout({super.key, required this.shell});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: shell,
    bottomNavigationBar: NavigationBar(
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
  );
}
