import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Admin shell; navigation content arrives with M6.
class AdminLayout extends StatelessWidget {
  final StatefulNavigationShell shell;

  const AdminLayout({super.key, required this.shell});

  @override
  Widget build(BuildContext context) => Scaffold(body: shell);
}
