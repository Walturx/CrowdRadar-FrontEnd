import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/categoria_lugar.dart';
import '../../../core/models/enum_api.dart';
import '../../../core/models/nivel_saturacion.dart';
import '../../../core/widgets/chip_saturacion.dart';
import '../../../core/widgets/medidor_nivel.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_shadows.dart';
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
        builder: (context, state) => switch (state) {
          ExplorarCargando() => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: LinearProgressIndicator(minHeight: 2),
          ),
          ExplorarError() => _Error(
            onReintentar: context.read<ExplorarCubit>().cargarCategorias,
          ),
          ExplorarCargado() => _Controles(state),
        },
      ),
    );
  }
}

/// `shadow-1` of the design system (section 4): cards and chips.
class _Controles extends StatelessWidget {
  final ExplorarCargado estado;

  const _Controles(this.estado);

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ExplorarCubit>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FilaChips(
          children: [
            _ChipFiltro(
              key: const Key('chip-categoria-todos'),
              inicio: const Icon(Icons.grid_view_rounded),
              etiqueta: const Text('Todos'),
              seleccionado: estado.categoria == null,
              onTap: () => cubit.seleccionarCategoria(null),
            ),
            for (final c in estado.categorias)
              _ChipFiltro(
                key: Key('chip-categoria-${c.categoria?.name}'),
                inicio: Icon(
                  iconoCategoria(c.categoria),
                  key: Key('icono-categoria-${c.categoria?.name}'),
                ),
                etiqueta: Text(c.etiqueta),
                seleccionado: c.categoria == estado.categoria,
                onTap: () => cubit.seleccionarCategoria(c.categoria),
              ),
          ],
        ),
        _FilaChips(
          children: [
            _ChipFiltro(
              key: const Key('chip-nivel-todos'),
              etiqueta: const Text('Todos', key: Key('nivel-todos')),
              seleccionado: estado.saturacion == null,
              // The chosen "all levels" chip is ink, not brand (design-system).
              colorElegido: AppColors.text,
              onTap: () => cubit.seleccionarSaturacion(null),
            ),
            for (final n in FiltrosMapa.niveles)
              _ChipFiltro(
                key: Key('chip-nivel-${valorApi(n).toLowerCase()}'),
                // The meter makes the level chips the map legend (D3).
                inicio: MedidorNivel(
                  nivel: n,
                  color: estado.saturacion == n
                      ? AppColors.surface
                      : ChipSaturacion.fgDe(n),
                ),
                etiqueta: Text(
                  ChipSaturacion.etiquetaDe(n),
                  key: Key('nivel-${valorApi(n).toLowerCase()}'),
                ),
                seleccionado: estado.saturacion == n,
                onTap: () => cubit.seleccionarSaturacion(n),
              ),
          ],
        ),
      ],
    );
  }
}

/// One horizontally scrolling row of filter chips, 8 px apart.
class _FilaChips extends StatelessWidget {
  final List<Widget> children;

  const _FilaChips({required this.children});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      // The chip shadows must not be clipped by the scroll view.
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Filter chip (design-system section 5): a 36 px pill inside a 44 px touch
/// target. Unselected it is white with `shadow-1`; selected it takes
/// [colorElegido] (brand by default) with white text and icons.
class _ChipFiltro extends StatelessWidget {
  static const double _alto = 36;
  static const double _altoTactil = 44;

  final Widget etiqueta;
  final Widget? inicio;
  final bool seleccionado;
  final Color colorElegido;
  final VoidCallback onTap;

  const _ChipFiltro({
    super.key,
    required this.etiqueta,
    required this.seleccionado,
    required this.onTap,
    this.inicio,
    this.colorElegido = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final primerPlano = seleccionado
        ? AppColors.surface
        : AppColors.textSecondary;
    const forma = StadiumBorder();
    return Semantics(
      container: true,
      button: true,
      selected: seleccionado,
      // The whole 44 px target answers, not only the visible 36 px pill.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: _altoTactil,
            minWidth: _altoTactil,
          ),
          child: Center(
            widthFactor: 1,
            child: DecoratedBox(
              decoration: const ShapeDecoration(
                shape: forma,
                shadows: AppShadows.card,
              ),
              child: Material(
                color: seleccionado ? colorElegido : AppColors.surface,
                shape: forma,
                clipBehavior: Clip.antiAlias,
                // Only paints the ripple: the outer detector owns the tap and
                // its semantics, so the label and state stay on one node.
                child: InkWell(
                  onTap: onTap,
                  canRequestFocus: false,
                  excludeFromSemantics: true,
                  child: Container(
                    height: _alto,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: IconTheme.merge(
                      data: IconThemeData(size: 18, color: primerPlano),
                      child: DefaultTextStyle.merge(
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          color: primerPlano,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (inicio != null) ...[
                              inicio!,
                              const SizedBox(width: 6),
                            ],
                            etiqueta,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  final VoidCallback onReintentar;

  const _Error({required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.only(left: 14, right: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          const Expanded(child: Text(FiltrosMapa.mensajeError)),
          TextButton(onPressed: onReintentar, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
