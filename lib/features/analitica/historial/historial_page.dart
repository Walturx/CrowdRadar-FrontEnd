import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/rutas.dart';
import '../../../core/models/analitica.dart';
import '../../../theme/app_colors.dart';
import '../data/analitica_repository.dart';
import '../widgets/grafico_barras.dart';
import '../widgets/vista_analitica.dart';
import 'historial_lugar_cubit.dart';

/// HU 6.1: crowding history of a place, chronological.
class HistorialPage extends StatelessWidget {
  final int lugarId;

  const HistorialPage({super.key, required this.lugarId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          HistorialLugarCubit(context.read<AnaliticaRepository>(), lugarId)
            ..cargar(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Historial de aforo')),
        body: Column(
          children: [
            const _Selector(),
            Expanded(
              child: VistaAnalitica<HistorialLugarCubit, SerieSaturacion>(
                tituloSinDatos: 'Sin historial todavía',
                mensajeSinDatos:
                    'Aún no hay suficientes reportes para mostrar el comportamiento de aforo de este lugar.',
                esSintetico: (s) => s.sintetico,
                construir: (context, serie) => _Contenido(serie, lugarId),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `shadow-1` of the design system (cards and chips).
const List<BoxShadow> _sombra1 = [
  BoxShadow(color: Color(0x0F0F172A), offset: Offset(0, 1), blurRadius: 2),
  BoxShadow(color: Color(0x0A0F172A), offset: Offset(0, 1), blurRadius: 1),
];

/// White card of the design system: radius 20, `line` border, `shadow-1`.
BoxDecoration _decoracionTarjeta() => BoxDecoration(
  color: AppColors.surface,
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: AppColors.border),
  boxShadow: _sombra1,
);

/// Hoy / 7 días as a segmented control.
class _Selector extends StatelessWidget {
  const _Selector();

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<HistorialLugarCubit>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.sinDatosBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            for (final (agrupacion, texto, clave) in const [
              (AgrupacionHistorial.hora, 'Hoy', 'pestana-hoy'),
              (AgrupacionHistorial.dia, '7 días', 'pestana-7-dias'),
            ])
              Expanded(
                child: _Pestana(
                  key: Key(clave),
                  texto: texto,
                  elegida: cubit.agrupacion == agrupacion,
                  onTap: () => cubit.seleccionar(agrupacion),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Pestana extends StatelessWidget {
  final String texto;
  final bool elegida;
  final VoidCallback onTap;

  const _Pestana({
    super.key,
    required this.texto,
    required this.elegida,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: elegida,
    excludeSemantics: true,
    label: texto,
    child: Material(
      color: elegida ? AppColors.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          decoration: elegida
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: _sombra1,
                )
              : null,
          child: Text(
            texto,
            style: TextStyle(
              fontSize: 14,
              fontWeight: elegida ? FontWeight.w700 : FontWeight.w500,
              color: elegida ? AppColors.text : AppColors.textMuted,
            ),
          ),
        ),
      ),
    ),
  );
}

class _Contenido extends StatelessWidget {
  final SerieSaturacion serie;
  final int lugarId;

  const _Contenido(this.serie, this.lugarId);

  @override
  Widget build(BuildContext context) {
    final porHora =
        context.read<HistorialLugarCubit>().agrupacion ==
        AgrupacionHistorial.hora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Cómo varía la saturación durante el día',
          style: TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
        if (porHora) ...[
          const SizedBox(height: 12),
          _ResumenHoras(serie.puntos),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          decoration: _decoracionTarjeta(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EtiquetaSeccion(
                porHora
                    ? 'SATURACIÓN POR HORA · HOY'
                    : 'SATURACIÓN POR DÍA · ÚLTIMOS 7 DÍAS',
              ),
              GraficoBarras(
                puntos: serie.puntos,
                eje: porHora ? GraficoBarras.ejeHoras : null,
              ),
              const SizedBox(height: 12),
              const LeyendaBarras(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: _decoracionTarjeta(),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              children: [
                _FilaEnlace(
                  key: const Key('fila-comparar-periodos'),
                  icono: Icons.compare_arrows,
                  titulo: 'Comparar periodos',
                  onTap: () => context.push(Rutas.comparar(lugarId)),
                ),
                const Divider(height: 1, color: AppColors.border),
                _FilaEnlace(
                  key: const Key('fila-mejor-horario'),
                  icono: Icons.auto_awesome_outlined,
                  titulo: 'Mejor horario',
                  onTap: () => context.push(Rutas.mejorHorario(lugarId)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// "Horas con reportes": how many of the day's slots have samples. Derived
/// from the series only; the current hour is not shown because the slot ↔
/// device clock mapping is not guaranteed by the data.
class _ResumenHoras extends StatelessWidget {
  final List<PuntoSerie> puntos;

  const _ResumenHoras(this.puntos);

  @override
  Widget build(BuildContext context) {
    final conReportes = puntos.where((p) => p.muestras > 0).length;
    return Container(
      key: const Key('resumen-horas-con-reportes'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: _decoracionTarjeta(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Horas con reportes',
            style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            '$conReportes de ${puntos.length}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// List row (design-system §5): a 36 px icon on `primarySoft`, the title and
/// a chevron, at least 56 px high.
class _FilaEnlace extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final VoidCallback onTap;

  const _FilaEnlace({
    super.key,
    required this.icono,
    required this.titulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icono, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.iconMuted),
        ],
      ),
    ),
  );
}
