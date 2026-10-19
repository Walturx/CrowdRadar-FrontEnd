import '../../../core/widgets/lista_perezosa.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/cargando.dart';
import '../../../core/widgets/estado_error.dart';
import '../../../core/widgets/estado_vacio.dart';
import '../../../theme/app_colors.dart';
import '../comun/analitica_cubit.dart';
import '../comun/analitica_state.dart';

/// Small section label ("SATURACIÓN POR HORA").
class EtiquetaSeccion extends StatelessWidget {
  final String texto;

  const EtiquetaSeccion(this.texto, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(
      texto,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.6,
        color: AppColors.textMuted,
      ),
    ),
  );
}

/// Disclosure shown when the data is synthetic (fake or seeded backend).
class AvisoDemo extends StatelessWidget {
  static const String texto = 'Datos de demostración';

  const AvisoDemo({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: 16),
    child: Row(
      children: [
        Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
        SizedBox(width: 6),
        Text(texto, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ],
    ),
  );
}

/// Loading / empty / error / content switch shared by the analytics screens.
class VistaAnalitica<C extends AnaliticaCubit<T>, T> extends StatelessWidget {
  final String tituloSinDatos;
  final String mensajeSinDatos;
  final Widget Function(BuildContext context, T datos) construir;
  final bool Function(T datos) esSintetico;

  const VistaAnalitica({
    super.key,
    required this.tituloSinDatos,
    required this.mensajeSinDatos,
    required this.construir,
    required this.esSintetico,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<C, AnaliticaState<T>>(
      builder: (context, state) => switch (state) {
        AnaliticaCargando() => const Cargando(),
        AnaliticaSinDatos(:final mensaje) => EstadoVacio(
          icon: Icons.bar_chart,
          title: tituloSinDatos,
          subtitle: mensaje ?? mensajeSinDatos,
        ),
        AnaliticaError(:final mensaje) => EstadoError(
          mensaje: mensaje,
          onReintentar: () => context.read<C>().cargar(),
        ),
        AnaliticaCargado(:final datos) => ListaPerezosa.secciones(
          padding: const EdgeInsets.all(16),
          secciones: [
            construir(context, datos),
            if (esSintetico(datos)) const AvisoDemo(),
          ],
        ),
      },
    );
  }
}
