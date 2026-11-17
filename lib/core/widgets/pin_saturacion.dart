import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/nivel_saturacion.dart';
import 'chip_saturacion.dart';
import 'medidor_nivel.dart';

/// Map pin (design-system §5): a 34 px drop with a 2.5 px white border,
/// filled with the level `dot` color, with the meter in white inside it.
///
/// The drop sits at the bottom centre of a [ancho] × [alto] touch target, so
/// its tip is the widget's bottom centre.
class PinSaturacion extends StatelessWidget {
  static const double ancho = 44;
  static const double alto = 44;
  static const double _gota = 34;
  static const double _borde = 2.5;

  /// The drop is a square rounded on 3 corners and rotated 45°: its sharp
  /// corner ends half a diagonal below the square's centre.
  static final double _altoGota = _gota / 2 + _gota * math.sqrt2 / 2;

  final NivelSaturacion nivel;
  final String? etiqueta;
  final VoidCallback? onTap;

  const PinSaturacion({
    super.key,
    required this.nivel,
    this.etiqueta,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final arriba = alto - _altoGota;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Tooltip(
        message: etiqueta ?? '',
        child: SizedBox(
          width: ancho,
          height: alto,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: (ancho - _gota) / 2,
                top: arriba,
                width: _gota,
                height: _gota,
                child: Transform.rotate(
                  angle: math.pi / 4,
                  child: Container(
                    key: const ValueKey('pin-saturacion-icono'),
                    decoration: BoxDecoration(
                      color: ChipSaturacion.colorDe(nivel),
                      border: Border.all(color: Colors.white, width: _borde),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(_gota / 2),
                        topRight: Radius.circular(_gota / 2),
                        bottomLeft: Radius.circular(_gota / 2),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: (ancho - _gota) / 2,
                top: arriba,
                width: _gota,
                height: _gota,
                child: Center(
                  child: MedidorNivel(nivel: nivel, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
