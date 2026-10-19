import '../../../core/widgets/lista_perezosa.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/cargando.dart';
import '../../../core/widgets/confirmar_accion.dart';
import '../../../core/widgets/estado_error.dart';
import '../../../core/widgets/etiqueta_seccion.dart';
import '../../../core/widgets/mostrar_aviso.dart';
import '../data/moderacion_repository.dart';
import '../widgets/chip_estado_cuenta.dart';
import 'suspender_dialog.dart';
import 'usuario_admin_detalle_cubit.dart';
import 'usuario_admin_detalle_state.dart';

/// HU 7.2 c3, 7.3, 7.4: user detail with suspend and reactivate (`/admin/usuarios/:id`).
class UsuarioAdminDetallePage extends StatelessWidget {
  final int usuarioId;

  const UsuarioAdminDetallePage({super.key, required this.usuarioId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UsuarioAdminDetalleCubit(
        context.read<ModeracionRepository>(),
        usuarioId,
      )..cargar(),
      child: BlocConsumer<UsuarioAdminDetalleCubit, UsuarioAdminDetalleState>(
        listenWhen: (a, b) =>
            b is UsuarioAdminDetalleCargado && b.aviso != null,
        listener: (context, state) {
          mostrarAviso(context, (state as UsuarioAdminDetalleCargado).aviso!);
          context.read<UsuarioAdminDetalleCubit>().descartarAviso();
        },
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Detalle de usuario')),
          body: switch (state) {
            UsuarioAdminDetalleCargando() => const Cargando(),
            UsuarioAdminDetalleError() => EstadoError(
              mensaje: state.mensaje,
              onReintentar: state.codigo == 'USUARIO_NO_ENCONTRADO'
                  ? null
                  : () => context.read<UsuarioAdminDetalleCubit>().cargar(),
            ),
            UsuarioAdminDetalleCargado() => _Contenido(state),
          },
        ),
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  final UsuarioAdminDetalleCargado estado;

  const _Contenido(this.estado);

  @override
  Widget build(BuildContext context) {
    final u = estado.usuario;
    return ListaPerezosa.secciones(
      padding: const EdgeInsets.all(16),
      secciones: [
        Text(
          u.nombreCompleto,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        Text(u.email),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            u.estaSuspendido ? 'Cuenta suspendida' : 'Cuenta activa',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const EtiquetaSeccion('INFORMACIÓN DE LA CUENTA'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _Dato('Nombre', u.nombreCompleto),
                _Dato('Correo', u.email),
                _Dato(
                  'Estado',
                  u.estaSuspendido
                      ? textoSuspension('Suspendida', u.sancionVigente)
                      : 'Activa',
                ),
                _Dato('Reportes publicados', '${u.reportesPublicados}'),
                _Dato('Reportes denunciados', '${u.reportesDenunciados}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (u.estaSuspendido)
          ElevatedButton(
            onPressed: estado.enCurso ? null : () => _reactivar(context),
            child: const Text('Reactivar cuenta'),
          )
        else if (!u.esAdmin)
          ElevatedButton(
            onPressed: estado.enCurso ? null : () => _suspender(context),
            child: const Text('Suspender usuario'),
          ),
      ],
    );
  }

  Future<void> _suspender(BuildContext context) async {
    final cubit = context.read<UsuarioAdminDetalleCubit>();
    final eleccion = await mostrarSuspenderDialog(
      context,
      nombre: estado.usuario.nombreCompleto,
    );
    if (eleccion != null) await cubit.suspender(eleccion.dias, eleccion.motivo);
  }

  Future<void> _reactivar(BuildContext context) async {
    final cubit = context.read<UsuarioAdminDetalleCubit>();
    final confirmado = await confirmarAccion(
      context,
      titulo: 'Reactivar cuenta',
      contenido:
          '${estado.usuario.nombreCompleto} recuperará el acceso a CrowdRadar.',
      etiquetaConfirmar: 'Reactivar',
    );
    if (confirmado) await cubit.reactivar();
  }
}

class _Dato extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _Dato(this.etiqueta, this.valor);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(etiqueta),
        Flexible(
          child: Text(
            valor,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
