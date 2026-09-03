import 'package:flutter/material.dart';

import '../../../core/widgets/estado_vacio.dart';

class ValidarPage extends StatelessWidget {
  const ValidarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Validar reportes')),
      body: const EstadoVacio(
        icon: Icons.shield_outlined,
        title: 'Validar reportes',
        subtitle: 'Pronto vas a poder validar los reportes de aforo de otros usuarios.',
      ),
    );
  }
}
