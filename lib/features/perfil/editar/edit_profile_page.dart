import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'editar_perfil_cubit.dart';
import 'editar_perfil_state.dart';

import '../../../core/models/usuario.dart';

import '../../../core/widgets/boton_principal.dart';
import '../../../core/widgets/cargando.dart';
import '../data/perfil_repository.dart';

import '../../../core/utils/validadores.dart';

class EditProfilePage extends StatelessWidget {
  final Usuario? user;

  const EditProfilePage({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EditarPerfilCubit(context.read<PerfilRepository>()),
      child: _EditProfileView(user: user),
    );
  }
}

class _EditProfileView extends StatefulWidget {
  final Usuario? user;

  const _EditProfileView({this.user});

  @override
  State<_EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<_EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _apellidoCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _distritoCtrl;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.user?.nombre ?? '');
    _apellidoCtrl = TextEditingController(text: widget.user?.apellido ?? '');
    _telefonoCtrl = TextEditingController(text: widget.user?.telefono ?? '');
    _distritoCtrl = TextEditingController(text: widget.user?.distrito ?? '');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _telefonoCtrl.dispose();
    _distritoCtrl.dispose();
    super.dispose();
  }

  void _onGuardar(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      final cambios = {
        'nombre': _nombreCtrl.text.trim(),
        'apellido': _apellidoCtrl.text.trim(),
        'telefono': _telefonoCtrl.text.trim(),
        'distrito': _distritoCtrl.text.trim(),
      };
      context.read<EditarPerfilCubit>().guardar(cambios);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EditarPerfilCubit, EditarPerfilState>(
      listener: (context, state) {
        if (state is EditarPerfilGuardado) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil actualizado correctamente')),
          );
          context.pop();
        } else if (state is EditarPerfilFallido) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.mensaje)),
          );
        }
      },
      builder: (context, state) {
        if (state is EditarPerfilGuardando) {
          return const Scaffold(
            body: Cargando(),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Editar perfil')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nombreCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: Validadores.nombreApellido,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _apellidoCtrl,
                    decoration: const InputDecoration(labelText: 'Apellido'),
                    validator: Validadores.nombreApellido,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    enabled: false,
                    initialValue: widget.user?.email ?? '',
                    decoration: const InputDecoration(labelText: 'Correo electrónico'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _telefonoCtrl,
                    keyboardType: TextInputType.phone,
                    maxLength: 9,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      counterText: '',
                    ),
                    validator: Validadores.requerido,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _distritoCtrl,
                    decoration: const InputDecoration(labelText: 'Distrito'),
                    validator: Validadores.requerido,
                  ),
                  const SizedBox(height: 24),
                  BotonPrincipal(texto: 'Guardar cambios', onPressed: () => _onGuardar(context)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
