import 'package:flutter/material.dart';

/// `ListView.builder` for "header + N rows + footer" screens: the few header
/// and footer widgets are given eagerly, the rows are built lazily on demand
/// (each one behind the builder's default repaint boundary).
class ListaPerezosa extends StatelessWidget {
  final List<Widget> cabecera;
  final int cantidad;
  final IndexedWidgetBuilder fila;
  final List<Widget> pie;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  const ListaPerezosa({
    super.key,
    this.cabecera = const [],
    required this.cantidad,
    required this.fila,
    this.pie = const [],
    this.padding,
    this.physics,
  });

  /// Short static screens (detail pages, forms): every section is a widget
  /// of its own, still mounted through the builder.
  const ListaPerezosa.secciones({
    super.key,
    required List<Widget> secciones,
    this.padding,
    this.physics,
  }) : cabecera = secciones,
       cantidad = 0,
       fila = _sinFilas,
       pie = const [];

  static Widget _sinFilas(BuildContext context, int i) =>
      throw StateError('ListaPerezosa.secciones has no rows');

  @override
  Widget build(BuildContext context) {
    final inicioPie = cabecera.length + cantidad;
    return ListView.builder(
      padding: padding,
      physics: physics,
      itemCount: inicioPie + pie.length,
      semanticChildCount: identical(fila, _sinFilas) ? null : cantidad,
      itemBuilder: (context, i) {
        if (i < cabecera.length) return cabecera[i];
        if (i >= inicioPie) return pie[i - inicioPie];
        return fila(context, i - cabecera.length);
      },
    );
  }
}
