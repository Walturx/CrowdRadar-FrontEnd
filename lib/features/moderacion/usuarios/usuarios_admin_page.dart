import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/rutas.dart';
import '../../../core/models/moderacion.dart';
import '../../../core/widgets/cargando.dart';
import '../../../core/widgets/estado_error.dart';
import '../../../core/widgets/estado_vacio.dart';
import '../../../core/widgets/lista_perezosa.dart';
import '../../../core/widgets/mostrar_aviso.dart';
import '../../../theme/app_colors.dart';
import '../data/moderacion_repository.dart';
import '../widgets/chip_estado_cuenta.dart';
import 'usuarios_admin_cubit.dart';
import 'usuarios_admin_state.dart';

/// HU 7.2 / 7.4: the admin user directory (`/admin/usuarios`).
class UsuariosAdminPage extends StatelessWidget {
  const UsuariosAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          UsuariosAdminCubit(context.read<ModeracionRepository>())..cargar(),
      child: BlocConsumer<UsuariosAdminCubit, UsuariosAdminState>(
        listenWhen: (a, b) => b is UsuariosAdminCargado && b.aviso != null,
        listener: (context, state) {
          mostrarAviso(context, (state as UsuariosAdminCargado).aviso!);
          context.read<UsuariosAdminCubit>().descartarAviso();
        },
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Usuarios registrados')),
          body: Column(
            children: [
              _Filtros(state),
              Expanded(
                child: switch (state) {
                  UsuariosAdminCargando() => const Cargando(),
                  UsuariosAdminError() => EstadoError(
                    mensaje: state.mensaje,
                    onReintentar: () =>
                        context.read<UsuariosAdminCubit>().cargar(),
                  ),
                  UsuariosAdminCargado() => _Lista(state),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Filtros extends StatelessWidget {
  static const _etiquetas = <EstadoCuenta?, String>{
    null: 'Todos',
    EstadoCuenta.activo: 'Activos',
    EstadoCuenta.suspendido: 'Suspendidos',
  };

  static const _ordenes = <OrdenUsuarios, String>{
    OrdenUsuarios.recientes: 'Más recientes',
    OrdenUsuarios.nombre: 'Nombre',
    OrdenUsuarios.karma: 'Karma',
  };

  final UsuariosAdminState estado;

  const _Filtros(this.estado);

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<UsuariosAdminCubit>();
    final actual = estado;
    final status = actual is UsuariosAdminCargado ? actual.status : null;
    final orden = actual is UsuariosAdminCargado
        ? actual.orden
        : OrdenUsuarios.recientes;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          TextField(
            onChanged: cubit.buscar,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Buscar por nombre o correo',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final e in _etiquetas.entries)
                      ChoiceChip(
                        label: Text(e.value),
                        selected: status == e.key,
                        onSelected: (_) => cubit.filtrar(e.key),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<OrdenUsuarios>(
                tooltip: 'Ordenar',
                icon: const Icon(Icons.sort),
                initialValue: orden,
                onSelected: cubit.ordenar,
                itemBuilder: (_) => [
                  for (final e in _ordenes.entries)
                    PopupMenuItem(value: e.key, child: Text(e.value)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  final UsuariosAdminCargado estado;

  const _Lista(this.estado);

  String get _encabezado {
    if (estado.q != null) return '${estado.total} COINCIDENCIAS';
    if (estado.status == EstadoCuenta.suspendido) {
      return '${estado.total} CUENTAS SUSPENDIDAS';
    }
    return '${estado.total} USUARIOS';
  }

  @override
  Widget build(BuildContext context) {
    if (estado.usuarios.isEmpty && !estado.actualizando) {
      final suspendidos =
          estado.q == null && estado.status == EstadoCuenta.suspendido;
      return EstadoVacio(
        icon: Icons.group_outlined,
        title: suspendidos ? 'No hay cuentas suspendidas' : 'Sin resultados',
        subtitle: suspendidos
            ? 'Todas las cuentas están activas.'
            : 'No hay usuarios que coincidan con tu búsqueda.',
      );
    }
    final cubit = context.read<UsuariosAdminCubit>();
    return ListaPerezosa(
      padding: const EdgeInsets.all(16),
      cabecera: [
        Text(
          _encabezado,
          style: const TextStyle(
            fontSize: 12,
            letterSpacing: 0.6,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
      ],
      cantidad: estado.usuarios.length,
      fila: (_, i) => _Fila(estado.usuarios[i]),
      pie: [
        if (estado.hayMas)
          Center(
            child: estado.cargandoMas
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  )
                : TextButton(
                    onPressed: cubit.cargarMas,
                    child: const Text('Cargar más'),
                  ),
          ),
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  final UsuarioAdmin usuario;

  const _Fila(this.usuario);

  String get _iniciales {
    final n = usuario.nombre.isEmpty ? '?' : usuario.nombre[0];
    final a = usuario.apellido.isEmpty ? '' : usuario.apellido[0];
    return '$n$a'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(_iniciales)),
        title: Text(usuario.nombreCompleto),
        subtitle: Text(
          usuario.estaSuspendido
              ? textoSuspension('Suspendido', usuario.sancionVigente)
              : usuario.email,
        ),
        trailing: ChipEstadoCuenta(estado: usuario.status),
        onTap: () async {
          final cubit = context.read<UsuariosAdminCubit>();
          await context.push<void>(Rutas.adminUsuario(usuario.id));
          cubit.cargar();
        },
      ),
    );
  }
}
