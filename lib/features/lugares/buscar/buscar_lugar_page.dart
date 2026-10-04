import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/map/tipos_mapa.dart';
import '../../../core/models/lugar_resumen.dart';
import '../../../core/utils/distancia.dart';
import '../../../core/widgets/cargando.dart';
import '../../../core/widgets/chip_saturacion.dart';
import '../../../core/widgets/estado_error.dart';
import '../../../core/widgets/estado_vacio.dart';
import '../../../theme/app_colors.dart';
import '../categoria_presentacion.dart';
import '../data/lugar_repository.dart';
import 'buscar_lugar_cubit.dart';
import 'buscar_lugar_state.dart';

/// Search by name (HU 3.4). Pops with the id of the chosen place; the caller
/// decides where to go. [centroMapa] enables the distance in each result.
class BuscarLugarPage extends StatelessWidget {
  static const int maximoCaracteres = 60;
  static const String ayuda = 'Escribe al menos 2 caracteres para buscar';

  final PuntoGeografico? centroMapa;

  const BuscarLugarPage({super.key, this.centroMapa});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BuscarLugarCubit(context.read<LugarRepository>()),
      child: _BuscarView(centroMapa),
    );
  }
}

class _BuscarView extends StatelessWidget {
  final PuntoGeografico? centroMapa;

  const _BuscarView(this.centroMapa);

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BuscarLugarCubit>();
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          maxLength: BuscarLugarPage.maximoCaracteres,
          decoration: const InputDecoration(
            hintText: 'Buscar lugares',
            counterText: '',
            border: InputBorder.none,
          ),
          onChanged: cubit.alCambiarTexto,
        ),
      ),
      body: BlocBuilder<BuscarLugarCubit, BuscarLugarState>(
        builder: (context, state) => switch (state) {
          BuscarInicial() => const EstadoVacio(
            icon: Icons.search,
            title: 'Buscar lugares',
            subtitle: BuscarLugarPage.ayuda,
          ),
          BuscarBuscando() => const Cargando(),
          BuscarResultados() => _Lista(state.lugares, centroMapa),
          BuscarSinResultados() => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Cabecera('SIN RESULTADOS'),
              Expanded(
                child: EstadoVacio(
                  icon: Icons.search_off,
                  title: 'Sin resultados',
                  subtitle: state.mensaje,
                ),
              ),
            ],
          ),
          BuscarError() => EstadoError(
            mensaje: state.mensaje,
            onReintentar: cubit.reintentar,
          ),
        },
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  final List<LugarResumen> lugares;
  final PuntoGeografico? centroMapa;

  const _Lista(this.lugares, this.centroMapa);

  String _subtitulo(LugarResumen l) {
    final categoria = etiquetaCategoria(l.categoria);
    final centro = centroMapa;
    if (centro == null) return categoria;
    final metros = distanciaMetros(
      centro,
      PuntoGeografico(l.latitud, l.longitud),
    );
    return '$categoria · ${formatoDistancia(metros)}';
  }

  @override
  Widget build(BuildContext context) {
    final n = lugares.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Cabecera('$n ${n == 1 ? "RESULTADO" : "RESULTADOS"}'),
        Expanded(
          child: ListView.builder(
            itemCount: n,
            itemBuilder: (context, i) {
              final l = lugares[i];
              return ListTile(
                leading: Text(
                  emojiCategoria(l.categoria),
                  style: const TextStyle(fontSize: 28),
                ),
                title: Text(l.nombre),
                subtitle: Text(_subtitulo(l)),
                trailing: ChipSaturacion(nivel: l.saturacion),
                onTap: () => Navigator.of(context).pop(l.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Cabecera extends StatelessWidget {
  final String texto;

  const _Cabecera(this.texto);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
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
