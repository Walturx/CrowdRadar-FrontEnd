import '../../../core/widgets/lista_perezosa.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/rutas.dart';
import '../../../core/widgets/cargando.dart';
import '../../../core/widgets/cerrar_sesion.dart';
import '../../../core/widgets/estado_error.dart';
import '../../../core/widgets/etiqueta_seccion.dart';
import '../../../theme/app_colors.dart';
import '../data/perfil_repository.dart';
import '../widgets/tarjeta_tier.dart';
import 'perfil_cubit.dart';
import 'perfil_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PerfilCubit(context.read<PerfilRepository>())..cargar(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  bool? _activa;

  /// Refreshes (keeping the data on screen) when the tab becomes active again,
  /// so a tier reached elsewhere (a report validated meanwhile) shows up.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final activa = TickerMode.valuesOf(context).enabled;
    if (_activa == false && activa) context.read<PerfilCubit>().refrescar();
    _activa = activa;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: BlocConsumer<PerfilCubit, PerfilState>(
        listenWhen: (_, actual) =>
            actual is PerfilCargado && actual.errorActualizacion != null,
        listener: (context, state) =>
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text((state as PerfilCargado).errorActualizacion!),
              ),
            ),
        builder: (context, state) {
          if (state is PerfilCargando) {
            return const Cargando();
          }
          if (state is PerfilError) {
            return EstadoError(
              mensaje: state.mensaje,
              onReintentar: () => context.read<PerfilCubit>().cargar(),
            );
          }

          final loaded = state as PerfilCargado;
          final user = loaded.usuario;

          final nombre = (user.nombre ?? '').trim();
          final apellido = (user.apellido ?? '').trim();
          final initials =
              ((nombre.isNotEmpty ? nombre[0] : '') +
                      (apellido.isNotEmpty ? apellido[0] : ''))
                  .toUpperCase();
          final fullName = '${user.nombre ?? ''} ${user.apellido ?? ''}'.trim();

          return ListaPerezosa.secciones(
            padding: const EdgeInsets.only(bottom: 24),
            secciones: [
              _Encabezado(
                iniciales: initials.isEmpty ? '?' : initials,
                nombre: fullName,
                email: user.email ?? '-',
              ),
              TarjetaTier(user.tier, puntos: user.puntos),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: EtiquetaSeccion('INFORMACIÓN'),
              ),
              _CuadriculaInfo(
                telefono: user.telefono ?? '-',
                distrito: user.distrito ?? '-',
                rol: user.rol ?? '-',
                estado: user.status ?? '-',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: EtiquetaSeccion('CUENTA'),
              ),
              _GrupoFilas(
                key: const ValueKey('perfil-acciones'),
                filas: [
                  _FilaPerfil(
                    icono: Icons.edit_outlined,
                    titulo: 'Editar perfil',
                    alTocar: () async {
                      await context.push(
                        Rutas.perfilEditar,
                        extra: loaded.usuario.toJson(),
                      );
                      if (context.mounted) {
                        context.read<PerfilCubit>().refrescar();
                      }
                    },
                  ),
                  _FilaPerfil(
                    icono: Icons.history,
                    titulo: 'Mis reportes',
                    alTocar: () => context.push(Rutas.perfilReportes),
                  ),
                  _FilaPerfil(
                    icono: Icons.lock_outline,
                    titulo: 'Cambiar contraseña',
                    alTocar: () => context.push(Rutas.perfilPassword),
                  ),
                  _FilaPerfil(
                    icono: Icons.info_outline,
                    titulo: 'Acerca de',
                    alTocar: () => context.push(Rutas.perfilAcerca),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _GrupoFilas(
                filas: [
                  _FilaPerfil(
                    icono: Icons.logout,
                    titulo: 'Cerrar sesión',
                    peligro: true,
                    // The router redirects to /login on SesionNoAutenticada.
                    alTocar: () => confirmarCerrarSesion(context),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Initials avatar in brand blue, then the name and the email (no band).
class _Encabezado extends StatelessWidget {
  static const double ladoAvatar = 52;

  final String iniciales;
  final String nombre;
  final String email;

  const _Encabezado({
    required this.iniciales,
    required this.nombre,
    required this.email,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
    child: Row(
      children: [
        Container(
          key: const ValueKey('perfil-avatar'),
          width: ladoAvatar,
          height: ladoAvatar,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            iniciales,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 19,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombre,
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 21,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                email,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Information section: two columns of small cards (icon, label, value).
class _CuadriculaInfo extends StatelessWidget {
  final String telefono;
  final String distrito;
  final String rol;
  final String estado;

  const _CuadriculaInfo({
    required this.telefono,
    required this.distrito,
    required this.rol,
    required this.estado,
  });

  @override
  Widget build(BuildContext context) {
    Widget fila(Widget a, Widget b) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: a),
          const SizedBox(width: 10),
          Expanded(child: b),
        ],
      ),
    );
    return Padding(
      key: const ValueKey('perfil-info'),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          fila(
            _TarjetaInfo(Icons.phone_outlined, 'Teléfono', Text(telefono)),
            _TarjetaInfo(
              Icons.location_city_outlined,
              'Distrito',
              Text(distrito),
            ),
          ),
          const SizedBox(height: 10),
          fila(
            _TarjetaInfo(Icons.verified_user_outlined, 'Rol', Text(rol)),
            _TarjetaInfo(Icons.info_outline, 'Estado', _ValorEstado(estado)),
          ),
        ],
      ),
    );
  }
}

/// Small card of the information grid: icon and label, then the value.
class _TarjetaInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget value;

  const _TarjetaInfo(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.textMuted, size: 15),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        DefaultTextStyle.merge(
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
          child: value,
        ),
      ],
    ),
  );
}

/// The account status exactly as the backend sends it, in the
/// `ChipEstadoCuenta` style: a green dot when active, danger with a block
/// icon when suspended, plain text otherwise.
class _ValorEstado extends StatelessWidget {
  final String estado;

  const _ValorEstado(this.estado);

  @override
  Widget build(BuildContext context) {
    final normalizado = estado.trim().toUpperCase();
    final activo = normalizado == 'ACTIVO';
    final suspendido = normalizado == 'SUSPENDIDO';
    if (!activo && !suspendido) return Text(estado);
    return Row(
      children: [
        if (activo)
          Container(
            key: const ValueKey('punto-estado-cuenta'),
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.tranquiloDot,
              shape: BoxShape.circle,
            ),
          )
        else
          const Icon(
            Icons.block,
            key: ValueKey('icono-estado-cuenta'),
            size: 14,
            color: AppColors.danger,
          ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            estado,
            style: TextStyle(
              color: activo ? AppColors.tranquilo : AppColors.danger,
            ),
          ),
        ),
      ],
    );
  }
}

/// White list card (radius 20, `border` line) holding rows split by dividers.
class _GrupoFilas extends StatelessWidget {
  final List<Widget> filas;

  const _GrupoFilas({super.key, required this.filas});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < filas.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: AppColors.border),
            filas[i],
          ],
        ],
      ),
    ),
  );
}

/// List row (design-system §5): at least 56 high, a 36 px icon on
/// `primarySoft`, the title and a chevron. A danger row is red, no chevron.
class _FilaPerfil extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final VoidCallback alTocar;
  final bool peligro;

  const _FilaPerfil({
    required this.icono,
    required this.titulo,
    required this.alTocar,
    this.peligro = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = peligro ? AppColors.danger : AppColors.primary;
    return InkWell(
      onTap: alTocar,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: peligro ? AppColors.dangerBg : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icono, color: color, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: peligro ? AppColors.danger : AppColors.text,
                  ),
                ),
              ),
              if (!peligro)
                const Icon(Icons.chevron_right, color: AppColors.iconMuted),
            ],
          ),
        ),
      ),
    );
  }
}
