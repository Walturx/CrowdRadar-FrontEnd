import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/politica_password.dart';
import '../../../core/utils/validadores.dart';
import '../../../core/widgets/boton_principal.dart';
import '../../../core/widgets/cargando.dart';
import '../../../theme/app_colors.dart';
import '../data/auth_repository.dart';
import 'registro_cubit.dart';
import 'registro_state.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (c) => RegistroCubit(c.read<AuthRepository>()),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _distritoCtrl = TextEditingController();

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _telefonoCtrl.dispose();
    _distritoCtrl.dispose();
    super.dispose();
  }

  void _onRegister(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<RegistroCubit>().registrar(
            nombre: _nombreCtrl.text.trim(),
            apellido: _apellidoCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            telefono: _telefonoCtrl.text.trim(),
            distrito: _distritoCtrl.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RegistroCubit, RegistroState>(
      listener: (context, state) {
        if (state is RegistroExitoso) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario registrado correctamente')),
          );
          context.pop();
        } else if (state is RegistroFallido) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.mensaje)),
          );
        }
      },
      builder: (context, state) {
        if (state is RegistroEnviando) {
          return const Scaffold(
            body: Cargando(),
          );
        }

        final errores =
            state is RegistroFallido ? state.erroresPorCampo : const <String, String>{};

        return Scaffold(
          appBar: AppBar(title: const Text('Crear cuenta')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Crea tu cuenta',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    key: const Key('campo-nombre'),
                    controller: _nombreCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      errorText: errores['nombre'],
                    ),
                    validator: Validadores.nombreApellido,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('campo-apellido'),
                    controller: _apellidoCtrl,
                    decoration: InputDecoration(
                      labelText: 'Apellido',
                      errorText: errores['apellido'],
                    ),
                    validator: Validadores.nombreApellido,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('campo-email'),
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      errorText: errores['email'],
                    ),
                    validator: Validadores.correo,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('campo-password'),
                    controller: _passwordCtrl,
                    obscureText: true,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      errorText: errores['password'],
                    ),
                    validator: validarPassword,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('campo-telefono'),
                    controller: _telefonoCtrl,
                    keyboardType: TextInputType.phone,
                    maxLength: 9,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Teléfono',
                      counterText: '',
                      errorText: errores['telefono'],
                    ),
                    validator: Validadores.telefono,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('campo-distrito'),
                    controller: _distritoCtrl,
                    decoration: InputDecoration(
                      labelText: 'Distrito',
                      errorText: errores['distrito'],
                    ),
                    validator: Validadores.distrito,
                  ),
                  const SizedBox(height: 24),
                  BotonPrincipal(texto: 'Registrarme', onPressed: () => _onRegister(context)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
