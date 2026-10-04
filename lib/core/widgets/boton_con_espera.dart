import 'dart:async';

import 'package:flutter/material.dart';

import 'boton_principal.dart';

/// [BotonPrincipal] that stays disabled while a server-imposed wait
/// ([segundos], from `Retry-After`) counts down, one tick per second.
class BotonConEspera extends StatefulWidget {
  final String texto;
  final VoidCallback? onPressed;
  final bool cargando;
  final int? segundos;

  const BotonConEspera({
    super.key,
    required this.texto,
    required this.onPressed,
    this.cargando = false,
    this.segundos,
  });

  @override
  State<BotonConEspera> createState() => _BotonConEsperaState();
}

class _BotonConEsperaState extends State<BotonConEspera> {
  Timer? _reloj;
  int _restantes = 0;

  @override
  void initState() {
    super.initState();
    _reiniciar();
  }

  @override
  void didUpdateWidget(BotonConEspera anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.segundos != widget.segundos) _reiniciar();
  }

  void _reiniciar() {
    _reloj?.cancel();
    _restantes = widget.segundos ?? 0;
    if (_restantes <= 0) return;
    _reloj = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _restantes--);
      if (_restantes <= 0) _reloj?.cancel();
    });
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esperando = _restantes > 0;
    return BotonPrincipal(
      texto: esperando ? '${widget.texto} (${_restantes}s)' : widget.texto,
      cargando: widget.cargando,
      onPressed: esperando ? null : widget.onPressed,
    );
  }
}
