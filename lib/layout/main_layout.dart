import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/push/receptor_push.dart';
import '../features/alertas/data/alerta_repository.dart';
import '../features/alertas/lista/alertas_cubit.dart';
import '../features/alertas/lista/alertas_state.dart';
import 'cr_bottom_nav.dart';

/// Shell with the bottom navigation (Mapa, Validar, Favoritos, Perfil).
///
/// It owns the [AlertasCubit] of the signed-in user: the Favoritos tab shows
/// its unread count and the alerts screen reads it. The alerts are reloaded
/// every time the app returns to the foreground and as soon as a push arrives
/// while it is in the foreground.
class MainLayout extends StatelessWidget {
  final StatefulNavigationShell shell;

  const MainLayout({super.key, required this.shell});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AlertasCubit(context.read<AlertaRepository>())..cargar(),
      child: _RecargarAlertas(
        child: Scaffold(
          body: shell,
          bottomNavigationBar: BlocSelector<AlertasCubit, AlertasState, int>(
            selector: (state) => state is AlertasCargado ? state.noLeidas : 0,
            builder: (context, noLeidas) => CrBottomNav(
              currentIndex: shell.currentIndex,
              alertasNoLeidas: noLeidas,
              onTap: (index) => shell.goBranch(
                index,
                initialLocation: index == shell.currentIndex,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Reloads the alerts when the app comes back to the foreground (throttled)
/// and right away when a push arrives in the foreground (it carries a new
/// alert, so the badge must count it).
class _RecargarAlertas extends StatefulWidget {
  final Widget child;

  const _RecargarAlertas({required this.child});

  @override
  State<_RecargarAlertas> createState() => _RecargarAlertasState();
}

class _RecargarAlertasState extends State<_RecargarAlertas>
    with WidgetsBindingObserver {
  StreamSubscription<MensajePrimerPlano>? _mensajes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final alertas = context.read<AlertasCubit>();
    _mensajes = context.read<ReceptorPush>().mensajesEnPrimerPlano.listen(
      (_) => alertas.refrescar(),
    );
  }

  @override
  void dispose() {
    _mensajes?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AlertasCubit>().alVolverAPrimerPlano();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
