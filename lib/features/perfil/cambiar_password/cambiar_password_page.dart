import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/session/motivo_cierre.dart';
import '../../../core/session/sesion_cubit.dart';
import '../../../core/widgets/boton_con_espera.dart';
import '../../../core/widgets/mostrar_aviso.dart';
import '../../../theme/app_colors.dart';
import '../data/perfil_repository.dart';
import 'cambiar_password_cubit.dart';
import 'cambiar_password_state.dart';
import '../../../core/utils/politica_password.dart';

/// HU 2.3: change the password. On success the session ends: the old token is
/// stale on the server, so the user signs in again.
class CambiarPasswordPage extends StatelessWidget {
  const CambiarPasswordPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (c) => CambiarPasswordCubit(c.read<PerfilRepository>()),
        child: const _CambiarPasswordView(),
      );
}

class _CambiarPasswordView extends StatefulWidget {
  const _CambiarPasswordView();

  @override
  State<_CambiarPasswordView> createState() => _CambiarPasswordViewState();
}

class _CambiarPasswordViewState extends State<_CambiarPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _actualCtrl = TextEditingController();
  final _nuevaCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();

  @override
  void dispose() {
    _actualCtrl.dispose();
    _nuevaCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  void _enviar(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<CambiarPasswordCubit>().cambiar(
          actual: _actualCtrl.text,
          nueva: _nuevaCtrl.text,
          confirmar: _confirmarCtrl.text,
        );
  }

  String? _obligatorio(String? v, String mensaje) =>
      v == null || v.isEmpty ? mensaje : null;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Cambiar contraseña')),
        body: BlocConsumer<CambiarPasswordCubit, CambiarPasswordState>(
          listener: (context, state) {
            if (state is CambiarPasswordExitoso) {
              mostrarAviso(context, state.mensaje);
              // The router sends the user to /login.
              context
                  .read<SesionCubit>()
                  .cerrarSesion(motivo: MotivoCierre.passwordCambiada);
            } else if (state is CambiarPasswordFallido) {
              mostrarAviso(context, state.mensaje);
            }
          },
          builder: (context, state) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    key: const Key('campo-password-actual'),
                    controller: _actualCtrl,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration:
                        const InputDecoration(labelText: 'Contraseña actual'),
                    validator: (v) =>
                        _obligatorio(v, 'Ingresá tu contraseña actual'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('campo-password-nueva'),
                    controller: _nuevaCtrl,
                    obscureText: true,
                    autofillHints: const [AutofillHints.newPassword],
                    onChanged: (_) => setState(() {}),
                    decoration:
                        const InputDecoration(labelText: 'Nueva contraseña'),
                    validator: (v) =>
                        _obligatorio(v, 'Ingresá la nueva contraseña'),
                  ),
                  const SizedBox(height: 8),
                  _ListaRequisitos(_nuevaCtrl.text),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('campo-password-confirmar'),
                    controller: _confirmarCtrl,
                    obscureText: true,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: const InputDecoration(
                        labelText: 'Confirmar nueva contraseña'),
                    validator: (v) =>
                        _obligatorio(v, 'Confirmá la nueva contraseña'),
                  ),
                  if (state is CambiarPasswordFallido &&
                      state.requisitosIncumplidos.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    for (final r in state.requisitosIncumplidos)
                      Text(r, style: const TextStyle(color: AppColors.danger)),
                  ],
                  const SizedBox(height: 24),
                  BotonConEspera(
                    texto: 'Cambiar contraseña',
                    cargando: state is CambiarPasswordEnviando,
                    segundos: state is CambiarPasswordFallido
                        ? state.reintentarEnSegundos
                        : null,
                    onPressed: () => _enviar(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

/// Live checklist of the policy for the typed [password].
class _ListaRequisitos extends StatelessWidget {
  final String password;

  const _ListaRequisitos(this.password);

  @override
  Widget build(BuildContext context) {
    final incumplidos = requisitosIncumplidos(password);
    return Column(
      children: [
        for (final r in RequisitoPassword.values)
          // The byte limit is a rare edge: shown only once exceeded.
          if (r != RequisitoPassword.maximoBytes || incumplidos.contains(r))
            Row(
            children: [
              Icon(
                incumplidos.contains(r)
                    ? Icons.radio_button_unchecked
                    : Icons.check_circle,
                size: 16,
                color: incumplidos.contains(r)
                    ? AppColors.textMuted
                    : AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                r.texto,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
