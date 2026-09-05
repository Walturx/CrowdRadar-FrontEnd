import '../utils/lectura_json.dart';

/// Successful API envelope `{message, data}` with parsed data.
class RespuestaApi<T> {
  final String mensaje;
  final T datos;

  const RespuestaApi({required this.mensaje, required this.datos});
}

/// Paginated envelope `{items, page, size, total, totalPaginas}`.
class Pagina<T> {
  final List<T> items;
  final int page;
  final int size;
  final int total;
  final int totalPaginas;

  const Pagina({
    required this.items,
    required this.page,
    required this.size,
    required this.total,
    required this.totalPaginas,
  });

  factory Pagina.fromJson(Object? json, T Function(Object? item) parser) {
    final mapa = aMapa(json);
    int entero(String clave, int porDefecto) {
      final v = mapa[clave];
      return v is num ? v.toInt() : porDefecto;
    }

    return Pagina(
      items: [for (final i in mapa['items'] as List? ?? const []) parser(i)],
      page: entero('page', 1),
      size: entero('size', 0),
      total: entero('total', 0),
      totalPaginas: entero('totalPaginas', 0),
    );
  }

  bool get hayMas => page < totalPaginas;
}

/// Non-paginated list; an empty result keeps its explanatory message.
class ResultadoLista<T> {
  final String mensaje;
  final List<T> items;

  const ResultadoLista({required this.mensaje, required this.items});

  bool get estaVacia => items.isEmpty;
}
