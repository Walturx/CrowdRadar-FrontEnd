import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/validacion.dart';
import '../../../core/widgets/boton_principal.dart';
import '../../../theme/app_colors.dart';
import '../data/validacion_repository.dart';
import 'denunciar_cubit.dart';
import 'denunciar_state.dart';

/// Opens the report sheet (HU 5.4). Completes with `true` when the report was
/// registered, or was already registered, so the caller refreshes.
Future<bool?> mostrarDenunciarSheet(
  BuildContext context, {
  required int reporteId,
}) {
  final repositorio = context.read<ValidacionRepository>();
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => BlocProvider(
      create: (_) => DenunciarCubit(repositorio, reporteId),
      child: const DenunciarSheet(),
    ),
  );
}

class DenunciarSheet extends StatefulWidget {
  static const Map<MotivoDenuncia, (String, String)> _motivos = {
    MotivoDenuncia.informacionFalsa: (
      'Información falsa',
      'El nivel reportado no coincide con la realidad',
    ),
    MotivoDenuncia.spam: ('Spam o repetido', 'Reporte duplicado o sin sentido'),
    MotivoDenuncia.contenidoInapropiado: (
      'Contenido inapropiado',
      'Incumple las normas de la comunidad',
    ),
    MotivoDenuncia.otro: ('Otro motivo', 'Describe brevemente el problema'),
  };

  const DenunciarSheet({super.key});

  @override
  State<DenunciarSheet> createState() => _DenunciarSheetState();
}

class _DenunciarSheetState extends State<DenunciarSheet> {
  final _detalle = TextEditingController();
  MotivoDenuncia? _motivo;

  @override
  void dispose() {
    _detalle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: BlocBuilder<DenunciarCubit, DenunciarState>(
        builder: (context, state) => SingleChildScrollView(
          child: switch (state) {
            DenunciarFormulario() => _formulario(context, state),
            DenunciarEnviado() => _cierre(
              context,
              'Denuncia enviada',
              'Gracias por avisar. El equipo de moderación revisará este reporte.',
              'Listo',
              true,
            ),
            DenunciarBloqueado() => _cierre(
              context,
              'No se pudo denunciar',
              state.mensaje,
              'Cerrar',
              state.mensaje == DenunciarCubit.mensajeYaRegistrada,
            ),
          },
        ),
      ),
    );
  }

  Widget _formulario(BuildContext context, DenunciarFormulario estado) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '¿Por qué lo denuncias?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const Text('Tu denuncia será revisada por el equipo de moderación.'),
        if (estado.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              estado.error!,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        RadioGroup<MotivoDenuncia>(
          groupValue: _motivo,
          onChanged: (m) => setState(() => _motivo = m),
          child: Column(
            children: [
              for (final e in DenunciarSheet._motivos.entries)
                RadioListTile<MotivoDenuncia>(
                  value: e.key,
                  title: Text(e.value.$1),
                  subtitle: Text(e.value.$2),
                ),
            ],
          ),
        ),
        if (_motivo == MotivoDenuncia.otro)
          TextField(
            controller: _detalle,
            maxLength: DenunciarCubit.maxDetalle,
            decoration: const InputDecoration(labelText: 'Detalle'),
          ),
        BotonPrincipal(
          texto: 'Enviar denuncia',
          cargando: estado.enviando,
          onPressed: () =>
              context.read<DenunciarCubit>().enviar(_motivo, _detalle.text),
        ),
      ],
    );
  }

  Widget _cierre(
    BuildContext context,
    String titulo,
    String mensaje,
    String boton,
    bool resultado,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          titulo,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        Text(mensaje, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        BotonPrincipal(
          texto: boton,
          onPressed: () => Navigator.pop(context, resultado),
        ),
      ],
    );
  }
}
