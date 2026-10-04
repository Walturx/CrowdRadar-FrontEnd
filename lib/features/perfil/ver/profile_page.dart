import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/rutas.dart';
import '../../../core/session/sesion_cubit.dart';
import '../../../core/widgets/cargando.dart';
import '../../../core/widgets/confirmar_accion.dart';
import '../../../core/widgets/estado_error.dart';
import '../../../theme/app_colors.dart';
import '../data/perfil_repository.dart';
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

/// HU 2.4: confirms before ending the session.
Future<void> _confirmarCerrarSesion(BuildContext context) async {
  final sesion = context.read<SesionCubit>();
  final confirmado = await confirmarAccion(
    context,
    titulo: '¿Cerrar sesión?',
    etiquetaConfirmar: 'Cerrar sesión',
  );
  // The router redirects to /login on SesionNoAutenticada.
  if (confirmado) await sesion.cerrarSesion();
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  bool? _activa;

  /// Refreshes (keeping the data on screen) when the tab becomes active again,
  /// so the karma earned by a report sent elsewhere shows up (HU 4.2 c2).
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

          Widget eyebrow(String text) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.6,
                color: AppColors.textMuted,
              ),
            ),
          );

          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Container(
                width: double.infinity,
                color: AppColors.primary,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Text(
                        initials.isEmpty ? '?' : initials,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email ?? '-',
                            style: const TextStyle(
                              color: AppColors.onPrimaryMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              eyebrow('CUENTA'),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      await context.push(
                        Rutas.perfilEditar,
                        extra: loaded.usuario.toJson(),
                      );
                      if (context.mounted) {
                        context.read<PerfilCubit>().refrescar();
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.bg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Text(
                              'Editar perfil',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
              eyebrow('INFORMACIÓN'),
              _TarjetaInfo(Icons.phone, 'Teléfono', user.telefono ?? '-'),
              _TarjetaInfo(
                Icons.location_city,
                'Distrito',
                user.distrito ?? '-',
              ),
              _TarjetaInfo(Icons.verified_user, 'Rol', user.rol ?? '-'),
              _TarjetaInfo(Icons.info_outline, 'Estado', user.status ?? '-'),
              _TarjetaKarma(user.puntosKarma ?? 0),
              _FilaPerfil(
                icono: Icons.history,
                titulo: 'Mis reportes',
                alTocar: () => context.push(Rutas.perfilReportes),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    // The router redirects to /login on SesionNoAutenticada.
                    onTap: () => _confirmarCerrarSesion(context),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.logout,
                              color: AppColors.danger,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Text(
                              'Cerrar sesión',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.danger,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Icon + label + value card of the information section.
class _TarjetaInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TarjetaInfo(this.icon, this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// HU 4.2: the accumulated karma points.
class _TarjetaKarma extends StatelessWidget {
  static const Key clave = Key('perfil-karma');

  final int puntos;

  const _TarjetaKarma(this.puntos);

  @override
  Widget build(BuildContext context) =>
      _TarjetaInfo(Icons.star, 'Karma', '$puntos', key: clave);
}

/// Tappable card row that opens a profile sub-screen.
class _FilaPerfil extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final VoidCallback alTocar;

  const _FilaPerfil({
    required this.icono,
    required this.titulo,
    required this.alTocar,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    child: Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        leading: Icon(icono, color: AppColors.primary),
        title: Text(titulo),
        trailing: const Icon(Icons.chevron_right),
        onTap: alTocar,
      ),
    ),
  );
}
