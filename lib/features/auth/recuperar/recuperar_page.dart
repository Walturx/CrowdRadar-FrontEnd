import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/rutas.dart';
import '../../../core/widgets/boton_principal.dart';
import '../../../core/widgets/mostrar_aviso.dart';
import '../../../theme/app_colors.dart';
import '../data/auth_repository.dart';
import 'recuperar_cubit.dart';
import 'recuperar_state.dart';

/// HU 2.1: asks the email and requests the recovery link.
class RecuperarPage extends StatelessWidget {
  const RecuperarPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (c) => RecuperarCubit(c.read<AuthRepository>()),
        child: const _RecuperarView(),
      );
}

class _RecuperarView extends StatefulWidget {
  const _RecuperarView();

  @override
  State<_RecuperarView> createState() => _RecuperarViewState();
}

class _RecuperarViewState extends State<_RecuperarView> {
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(title: const Text('Recuperar contraseña')),
        body: BlocConsumer<RecuperarCubit, RecuperarState>(
          // An invalid email is shown on the field, not in a snack bar.
          listenWhen: (_, actual) =>
              actual is RecuperarFallido &&
              actual.mensaje != RecuperarCubit.mensajeCorreoInvalido,
          listener: (context, state) =>
              mostrarAviso(context, (state as RecuperarFallido).mensaje),
          builder: (context, state) => Padding(
            padding: const EdgeInsets.all(24),
            child: state is RecuperarEnviado
                ? _Confirmacion(state.mensaje)
                : _Formulario(
                    controlador: _emailCtrl,
                    enviando: state is RecuperarEnviando,
                    error: state is RecuperarFallido ? state.mensaje : null,
                  ),
          ),
        ),
      );
}

class _Formulario extends StatelessWidget {
  final TextEditingController controlador;
  final bool enviando;
  final String? error;

  const _Formulario({
    required this.controlador,
    required this.enviando,
    required this.error,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Ingresá el correo de tu cuenta y te enviaremos un enlace para restablecer tu contraseña.',
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: controlador,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Correo electrónico',
              errorText: error == RecuperarCubit.mensajeCorreoInvalido ? error : null,
            ),
          ),
          const SizedBox(height: 24),
          BotonPrincipal(
            texto: 'Enviar enlace',
            cargando: enviando,
            onPressed: () => context.read<RecuperarCubit>().enviar(controlador.text),
          ),
        ],
      );
}

class _Confirmacion extends StatelessWidget {
  final String mensaje;

  const _Confirmacion(this.mensaje);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.mark_email_read, size: 56, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(mensaje, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => context.go(Rutas.login),
            child: const Text('Volver a iniciar sesión'),
          ),
        ],
      );
}
