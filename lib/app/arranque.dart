import 'package:flutter/material.dart';

import '../core/logging/registro_errores.dart';
import '../theme/app_theme.dart';
import 'app.dart';
import 'dependencias.dart';

/// Runs the async bootstrap (session restore + composition root) and shows
/// [PantallaErrorInicio] with a retry instead of a blank screen on failure.
class ArranqueApp extends StatefulWidget {
  final Future<Dependencias> Function() iniciar;
  final RegistroErrores registro;

  const ArranqueApp({
    super.key,
    required this.iniciar,
    this.registro = const RegistroErroresConsola(),
  });

  @override
  State<ArranqueApp> createState() => _ArranqueAppState();
}

class _ArranqueAppState extends State<ArranqueApp> {
  late Future<Dependencias> _futuro = _arrancar();

  Future<Dependencias> _arrancar() async {
    try {
      return await widget.iniciar();
    } catch (e, pila) {
      widget.registro.registrar('arranque', e, pila);
      rethrow;
    }
  }

  void _reintentar() {
    final nuevo = _arrancar();
    setState(() {
      _futuro = nuevo;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Dependencias>(
      future: _futuro,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return CrowdRadarApp(dependencias: snapshot.data!);
        }
        return MaterialApp(
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          home: snapshot.hasError
              ? PantallaErrorInicio(onReintentar: _reintentar)
              : const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
        );
      },
    );
  }
}

/// Minimal fatal-startup screen.
class PantallaErrorInicio extends StatelessWidget {
  final VoidCallback onReintentar;

  const PantallaErrorInicio({super.key, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No se pudo iniciar la aplicación'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onReintentar,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
