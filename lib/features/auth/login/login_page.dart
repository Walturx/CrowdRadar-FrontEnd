import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/rutas.dart';
import '../../../core/utils/validadores.dart';
import '../../../core/widgets/boton_con_espera.dart';
import '../../../core/widgets/cargando.dart';
import '../../../theme/app_colors.dart';
import '../data/auth_repository.dart';
import 'login_cubit.dart';
import 'login_state.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (c) => LoginCubit(c.read<AuthRepository>()),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _onLogin(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<LoginCubit>().iniciarSesion(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginCubit, LoginState>(
      listenWhen: (_, state) => state is LoginExitoso,
      listener: (context, state) {
        // The session guard sends an ADMIN on to the moderation panel.
        context.go(Rutas.mapa);
      },
      builder: (context, state) {
        if (state is LoginEnviando) {
          return const Scaffold(
            backgroundColor: AppColors.bg,
            body: Cargando(),
          );
        }

        // An API error shows above the form instead of in a snackbar.
        final error = state is LoginFallido ? state.mensaje : null;

        return Scaffold(
          backgroundColor: AppColors.bg,
          // Scrolls when the keyboard leaves less room than the form needs,
          // and keeps it centred otherwise.
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, viewport) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: viewport.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // The logo carries the wordmark, so the screen
                          // prints no separate app name. It is tightly
                          // cropped (about 1.85:1), hence a lower height than
                          // the old padded one for the same visual weight.
                          Center(
                            child: Image.asset(
                              'assets/images/crowdradar-logo.png',
                              height: 112,
                              semanticLabel: 'CrowdRadar',
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'Iniciar sesión',
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.675,
                              height: 1.2,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Mira qué tan lleno está un lugar antes de salir.',
                            style: TextStyle(
                              fontSize: 14.5,
                              height: 1.45,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (error != null) ...[
                            _AvisoError(mensaje: error),
                            const SizedBox(height: 16),
                          ],
                          _CampoConEtiqueta(
                            etiqueta: 'Correo electrónico',
                            campo: TextFormField(
                              key: const Key('campo-correo-login'),
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: _decoracion(
                                Icons.mail_outline,
                                conError: error != null,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Ingresa tu correo';
                                }
                                return Validadores.correo(value);
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _CampoConEtiqueta(
                            etiqueta: 'Contraseña',
                            campo: TextFormField(
                              key: const Key('campo-contrasena-login'),
                              controller: _passwordCtrl,
                              obscureText: true,
                              decoration: _decoracion(
                                Icons.lock_outline,
                                conError: error != null,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingresa tu contraseña';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              key: const Key('enlace-olvidaste-contrasena'),
                              style: _estiloEnlace,
                              onPressed: () => context.push(Rutas.recuperar),
                              child: const Text('¿Olvidaste tu contraseña?'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          BotonConEspera(
                            key: const Key('boton-iniciar-sesion'),
                            texto: 'Iniciar sesión',
                            segundos: state is LoginFallido
                                ? state.reintentarEnSegundos
                                : null,
                            onPressed: () => _onLogin(context),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton(
                              key: const Key('enlace-registrate'),
                              style: _estiloEnlace,
                              onPressed: () => context.push(Rutas.registro),
                              child: Text.rich(
                                TextSpan(
                                  text: '¿No tienes cuenta? ',
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  children: const [
                                    TextSpan(
                                      text: 'Regístrate',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Error look of the fields while an API error is shown (design-system §5).
const _bordeCampoError = Color(0xFFF3A6A6);
const _fondoCampoError = Color(0xFFFFFBFB);

/// Text links keep a touch target of at least 44 × 44 (design-system §1).
final _estiloEnlace = TextButton.styleFrom(minimumSize: const Size(44, 44));

InputDecoration _decoracion(IconData icono, {required bool conError}) {
  OutlineInputBorder borde(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: color, width: 1.5),
  );

  return InputDecoration(
    constraints: const BoxConstraints(minHeight: 54),
    prefixIcon: Icon(icono, size: 19, color: AppColors.iconMuted),
    fillColor: conError ? _fondoCampoError : null,
    enabledBorder: conError ? borde(_bordeCampoError) : null,
  );
}

/// A field with its label always visible above it. The label and the field
/// are merged into one semantics node so screen readers announce the label
/// together with the field.
class _CampoConEtiqueta extends StatelessWidget {
  final String etiqueta;
  final Widget campo;

  const _CampoConEtiqueta({required this.etiqueta, required this.campo});

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            etiqueta,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              height: 1.3,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          campo,
        ],
      ),
    );
  }
}

/// API error shown above the form, with the same message the snackbar used
/// to show.
class _AvisoError extends StatelessWidget {
  final String mensaje;

  const _AvisoError({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const ValueKey('aviso-error-login'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.dangerBg,
          border: Border.all(color: AppColors.dangerBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(
                Icons.info_outline,
                size: 18,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: AppColors.danger,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
