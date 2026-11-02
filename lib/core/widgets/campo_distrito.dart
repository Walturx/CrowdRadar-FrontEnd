import 'package:flutter/material.dart';

import '../utils/distritos.dart';
import '../utils/validadores.dart';

/// Required district dropdown shared by registration and profile editing.
/// A [inicial] value outside the list (older accounts) starts unselected, so the user picks again.
class CampoDistrito extends StatelessWidget {
  const CampoDistrito({
    super.key,
    this.inicial,
    this.errorText,
    required this.onChanged,
  });

  final String? inicial;
  final String? errorText;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: distritos.contains(inicial) ? inicial : null,
      isExpanded: true,
      menuMaxHeight: 320,
      hint: const Text('Selecciona tu distrito'),
      decoration: InputDecoration(labelText: 'Distrito', errorText: errorText),
      items: [
        for (final distrito in distritos)
          DropdownMenuItem(value: distrito, child: Text(distrito)),
      ],
      onChanged: onChanged,
      validator: Validadores.distrito,
    );
  }
}
