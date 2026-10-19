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

  /// Stable id of row `i` (e.g. the entity id). When given, each row is keyed
  /// by it and the list can find a row after the rows before it changed, so
  /// removing or updating an item never hands its state to another row.
  final Object Function(int i)? idFila;

  const ListaPerezosa({
    super.key,
    this.cabecera = const [],
    required this.cantidad,
    required this.fila,
    this.pie = const [],
    this.padding,
    this.physics,
    this.idFila,
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
       pie = const [],
       idFila = null;

  static Widget _sinFilas(BuildContext context, int i) =>
      throw StateError('ListaPerezosa.secciones has no rows');

  @override
  Widget build(BuildContext context) {
    final inicioPie = cabecera.length + cantidad;
    final idDe = idFila;
    Map<Object, int>? indices;
    return ListView.builder(
      padding: padding,
      physics: physics,
      itemCount: inicioPie + pie.length,
      semanticChildCount: identical(fila, _sinFilas) ? null : cantidad,
      findChildIndexCallback: idDe == null
          ? null
          : (clave) {
              if (clave is! _ClaveFila) return null;
              indices ??= {for (var i = 0; i < cantidad; i++) idDe(i): i};
              final i = indices![clave.value];
              return i == null ? null : cabecera.length + i;
            },
      itemBuilder: (context, i) {
        if (i < cabecera.length) return cabecera[i];
        if (i >= inicioPie) return pie[i - inicioPie];
        final f = i - cabecera.length;
        final hijo = fila(context, f);
        return idDe == null
            ? hijo
            : KeyedSubtree(key: _ClaveFila(idDe(f)), child: hijo);
      },
    );
  }
}

/// Its own type, so a row id never equals a header or footer `ValueKey`.
class _ClaveFila extends ValueKey<Object> {
  const _ClaveFila(super.value);
}
