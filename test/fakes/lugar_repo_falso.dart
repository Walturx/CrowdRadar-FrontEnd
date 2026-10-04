import 'package:crowdradar/core/map/tipos_mapa.dart';
import 'package:crowdradar/core/models/categoria_lugar.dart';
import 'package:crowdradar/core/models/lugar_detalle.dart';
import 'package:crowdradar/core/models/lugar_resumen.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/network/respuesta_api.dart';
import 'package:crowdradar/features/lugares/data/lugar_repository.dart';

/// One recorded `buscar` call.
typedef PedidoBuscar = ({String? q, LimitesMapa? bbox});

/// Scriptable [LugarRepository] that records what it was asked.
class RepoLugarFalso implements LugarRepository {
  Future<ResultadoLista<LugarResumen>> Function(PedidoBuscar pedido) alBuscar;
  Future<LugarDetalle> Function(int id) alObtener;

  final List<PedidoBuscar> pedidos = [];
  final List<int> detallesPedidos = [];

  RepoLugarFalso({
    Future<ResultadoLista<LugarResumen>> Function(PedidoBuscar pedido)?
    alBuscar,
    Future<LugarDetalle> Function(int id)? alObtener,
  }) : alBuscar =
           alBuscar ??
           ((_) async => const ResultadoLista(mensaje: '', items: [])),
       alObtener = alObtener ?? ((_) => throw UnimplementedError());

  @override
  Future<ResultadoLista<LugarResumen>> buscar({
    String? q,
    LimitesMapa? bbox,
    CategoriaLugar? categoria,
    NivelSaturacion? nivel,
    int? limite,
  }) {
    final pedido = (q: q, bbox: bbox);
    pedidos.add(pedido);
    return alBuscar(pedido);
  }

  @override
  Future<LugarDetalle> obtener(int id) {
    detallesPedidos.add(id);
    return alObtener(id);
  }
}

Future<ResultadoLista<LugarResumen>> resultado(
  List<LugarResumen> items, {
  String mensaje = '',
}) async => ResultadoLista(mensaje: mensaje, items: items);
