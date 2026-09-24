import 'package:equatable/equatable.dart';

import '../../../core/models/categoria_lugar.dart';
import '../../../core/models/nivel_saturacion.dart';

/// Query of `GET /api/lugares/explorar`. [lat] and [lng] go together; without
/// them the server lists by name and [radioKm] is ignored.
class FiltroExploracion extends Equatable {
  final CategoriaLugar? categoria;
  final NivelSaturacion? saturacion;
  final double? lat;
  final double? lng;
  final double? radioKm;

  const FiltroExploracion({
    this.categoria,
    this.saturacion,
    this.lat,
    this.lng,
    this.radioKm,
  });

  @override
  List<Object?> get props => [categoria, saturacion, lat, lng, radioKm];
}
