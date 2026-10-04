import 'package:flutter/material.dart';

import '../../../core/widgets/estado_vacio.dart';

class FavoritosPage extends StatelessWidget {
  const FavoritosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: const EstadoVacio(
        icon: Icons.favorite_border,
        title: 'Sin favoritos todavía',
        subtitle: 'Los lugares que marques como favoritos van a aparecer acá.',
      ),
    );
  }
}
