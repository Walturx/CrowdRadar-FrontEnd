import 'package:flutter/material.dart';

import 'usuario_admin_detalle_cubit.dart';

/// Choice made in the suspend dialog.
typedef SuspensionElegida = ({int dias, String motivo});

/// HU 7.3 c1: asks for the duration and the reason before suspending.
/// Completes with null when the admin cancels or dismisses it.
Future<SuspensionElegida?> mostrarSuspenderDialog(
  BuildContext context, {
  required String nombre,
  List<int> dias = UsuarioAdminDetalleCubit.diasPermitidos,
}) => showDialog<SuspensionElegida>(
  context: context,
  builder: (_) => _SuspenderDialog(nombre: nombre, dias: dias),
);

class _SuspenderDialog extends StatefulWidget {
  final String nombre;
  final List<int> dias;

  const _SuspenderDialog({required this.nombre, required this.dias});

  @override
  State<_SuspenderDialog> createState() => _SuspenderDialogState();
}

class _SuspenderDialogState extends State<_SuspenderDialog> {
  final _motivo = TextEditingController();
  int? _dias;

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  bool get _valido =>
      _dias != null &&
      _motivo.text.trim().length >= UsuarioAdminDetalleCubit.motivoMinimo;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Suspender usuario'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.nombre),
            const SizedBox(height: 12),
            const Text('Duración de la suspensión'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final d in widget.dias)
                  ChoiceChip(
                    label: Text('$d días'),
                    selected: _dias == d,
                    onSelected: (_) => setState(() => _dias = d),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _motivo,
              maxLength: UsuarioAdminDetalleCubit.motivoMaximo,
              maxLines: 3,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Motivo (mínimo 10 caracteres)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _valido
              ? () => Navigator.pop<SuspensionElegida>(context, (
                  dias: _dias!,
                  motivo: _motivo.text.trim(),
                ))
              : null,
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
