import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/categoria_lugar.dart';
import '../../../core/models/enum_api.dart';
import '../../../core/models/nivel_saturacion.dart';
import '../../../core/widgets/chip_saturacion.dart';
import '../../../theme/app_colors.dart';
import '../../lugares/categoria_presentacion.dart';
import '../data/exploracion_repository.dart';
import 'explorar_cubit.dart';
import 'explorar_state.dart';

/// HU 3.5 / 3.6 filter bar for the map: category chips ("Todos" first, the
/// server list after it) and a level control. [alCambiar] gets the whole
/// selection every time one of the filters changes.
class FiltrosMapa extends StatelessWidget {
  static const String mensajeError = 'No pudimos cargar las categorías';

  /// Levels the user can filter by ("Sin información" is not a choice).
  static const List<NivelSaturacion> niveles = [
    NivelSaturacion.tranquilo,
    NivelSaturacion.moderado,
    NivelSaturacion.saturado,
  ];

  final void Function(CategoriaLugar? categoria, NivelSaturacion? nivel)
  alCambiar;

  const FiltrosMapa({super.key, required this.alCambiar});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ExplorarCubit(context.read<ExploracionRepository>())
            ..cargarCategorias(),
      child: BlocConsumer<ExplorarCubit, ExplorarState>(
        listenWhen: (previo, actual) =>
            previo is ExplorarCargado &&
            actual is ExplorarCargado &&
            (previo.categoria != actual.categoria ||
                previo.saturacion != actual.saturacion),
        listener: (_, state) {
          final s = state as ExplorarCargado;
          alCambiar(s.categoria, s.saturacion);
        },
        builder: (context, state) => Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: switch (state) {
            ExplorarCargando() => const LinearProgressIndicator(minHeight: 2),
            ExplorarError() => _Error(
              onReintentar: context.read<ExplorarCubit>().cargarCategorias,
            ),
            ExplorarCargado() => _Controles(state),
          },
        ),
      ),
    );
  }
}

class _Controles extends StatelessWidget {
  final ExplorarCargado estado;

  const _Controles(this.estado);

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ExplorarCubit>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              ChoiceChip(
                key: const Key('chip-categoria-todos'),
                label: const Text('Todos'),
                selected: estado.categoria == null,
                onSelected: (_) => cubit.seleccionarCategoria(null),
              ),
              for (final c in estado.categorias)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    key: Key('chip-categoria-${c.categoria?.name}'),
                    avatar: Text(emojiCategoria(c.categoria)),
                    label: Text(c.etiqueta),
                    selected: c.categoria == estado.categoria,
                    onSelected: (_) => cubit.seleccionarCategoria(c.categoria),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          child: SegmentedButton<NivelSaturacion?>(
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: [
              const ButtonSegment(
                value: null,
                label: Text('Todos', key: Key('nivel-todos')),
              ),
              for (final n in FiltrosMapa.niveles)
                ButtonSegment(
                  value: n,
                  label: Text(
                    ChipSaturacion.etiquetaDe(n),
                    key: Key('nivel-${valorApi(n).toLowerCase()}'),
                  ),
                ),
            ],
            selected: {estado.saturacion},
            onSelectionChanged: (s) => cubit.seleccionarSaturacion(s.first),
          ),
        ),
      ],
    );
  }
}

class _Error extends StatelessWidget {
  final VoidCallback onReintentar;

  const _Error({required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Expanded(child: Text(FiltrosMapa.mensajeError)),
          TextButton(onPressed: onReintentar, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
