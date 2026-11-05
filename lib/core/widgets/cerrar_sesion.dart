import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../session/sesion_cubit.dart';
import 'confirmar_accion.dart';

/// HU 2.4: confirms before ending the session.
Future<void> confirmarCerrarSesion(BuildContext context) async {
  final sesion = context.read<SesionCubit>();
  final confirmado = await confirmarAccion(
    context,
    titulo: '¿Cerrar sesión?',
    etiquetaConfirmar: 'Cerrar sesión',
  );
  // The router redirects to /login on SesionNoAutenticada.
  if (confirmado) await sesion.cerrarSesion();
}

/// App bar action that signs out after confirming (admin panel).
class BotonCerrarSesion extends StatelessWidget {
  const BotonCerrarSesion({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Cerrar sesión',
    icon: const Icon(Icons.logout),
    onPressed: () => confirmarCerrarSesion(context),
  );
}
