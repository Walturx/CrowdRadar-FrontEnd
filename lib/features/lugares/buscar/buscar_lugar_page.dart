import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/map/tipos_mapa.dart';
import '../../../core/models/lugar_resumen.dart';
import '../../../core/widgets/cargando.dart';
import '../../../core/widgets/chip_saturacion.dart';
import '../../../core/widgets/estado_error.dart';
import '../../../core/widgets/estado_vacio.dart';
import '../../../core/widgets/etiqueta_seccion.dart';
import '../categoria_presentacion.dart';
import '../data/lugar_repository.dart';
import 'buscar_lugar_cubit.dart';
import 'buscar_lugar_state.dart';

/// Search by name (HU 3.4). Pops with the id of the chosen place; the caller
/// decides where to go. [centroMapa] enables the distance in each result.
class BuscarLugarPage extends StatelessWidget {
  static const int maximoCaracteres = 60;
  static const String ayuda =
      'Escribe al menos ${BuscarLugarCubit.minimoCaracteres} caracteres para buscar';
  static const EdgeInsets _relleno = EdgeInsets.fromLTRB(16, 12, 16, 4);

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
              const EtiquetaSeccion(
                'SIN RESULTADOS',
                relleno: BuscarLugarPage._relleno,
              ),
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

  @override
  Widget build(BuildContext context) {
    final n = lugares.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EtiquetaSeccion(
          '$n ${n == 1 ? "RESULTADO" : "RESULTADOS"}',
          relleno: BuscarLugarPage._relleno,
        ),
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
                subtitle: Text(
                  subtituloLugar(
                    l.categoria,
                    l.latitud,
                    l.longitud,
                    centroMapa,
                  ),
                ),
                trailing: ChipSaturacion(nivel: l.saturacion),
                onTap: () => context.pop(l.id),
              );
            },
          ),
        ),
      ],
    );
  }
}
