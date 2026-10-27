import 'package:equatable/equatable.dart';

import '../../../core/models/alerta.dart';
import '../../../core/network/respuesta_api.dart';

/// Platform of a push device token (wire values `ANDROID` / `IOS`).
enum PlataformaPush { android, ios }

/// One page of alerts plus the caller's total unread count.
class PaginaAlertas extends Equatable {
  final Pagina<Alerta> pagina;
  final int noLeidas;

  /// Server message; set when there are no alerts ("No tienes alertas.").
  final String mensaje;

  const PaginaAlertas({
    required this.pagina,
    required this.noLeidas,
    this.mensaje = '',
  });

  @override
  List<Object?> get props => [
    pagina.items,
    pagina.page,
    pagina.totalPaginas,
    noLeidas,
    mensaje,
  ];
}

/// Contract (M3). Failures are thrown as `ApiException`.
abstract class AlertaRepository {
  /// `GET /api/alertas`, newest first.
  Future<PaginaAlertas> listar({int page = 1, int size = 20});

  /// `PATCH /api/alertas/:id/leida` (idempotent; 404 `ALERTA_NO_ENCONTRADA`).
  Future<void> marcarLeida(int id);

  /// `POST /api/dispositivos` (201 new, 200 existing).
  Future<void> registrarDispositivo(String token, PlataformaPush plataforma);

  /// `DELETE /api/dispositivos/:token` (204, idempotent).
  Future<void> eliminarDispositivo(String token);
}
