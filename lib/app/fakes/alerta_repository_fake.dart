import '../../core/models/alerta.dart';
import '../../core/models/nivel_saturacion.dart';
import '../../core/session/session_service.dart';
import '../../core/widgets/chip_saturacion.dart';
import '../../features/alertas/data/alerta_repository.dart';
import 'comportamiento_fake.dart';
import 'datos_fake.dart';
import 'datos_lugares_fake.dart';

/// In-memory alerts and push devices with the backend rules (newest first,
/// idempotent mark-as-read, token upsert, 1-255 char tokens).
///
/// By default it starts with two deterministic alerts so the screens have
/// something to show; [emitir] simulates a saturation change on a place.
class AlertaRepositoryFake implements AlertaRepository {
  static const String mensajeVacio = 'No tienes alertas.';
  static const int _tokenMaximo = 255;

  final ComportamientoFake _comportamiento;
  final SessionService? _sesion;
  final DateTime Function() _reloj;

  /// Newest first.
  final List<Alerta> _alertas = [];
  final Set<String> _dispositivos = {};
  int _siguienteId = 1;

  AlertaRepositoryFake({
    ComportamientoFake comportamiento = const ComportamientoFake(),
    SessionService? sesion,
    DateTime Function()? reloj,
    bool sembrar = true,
  }) : _comportamiento = comportamiento,
       _sesion = sesion,
       _reloj = reloj ?? DateTime.now {
    if (sembrar) {
      emitir(2, NivelSaturacion.tranquilo, NivelSaturacion.moderado);
      _alertas[0] = _leida(_alertas[0]);
      emitir(1, NivelSaturacion.moderado, NivelSaturacion.saturado);
    }
  }

  /// Registered device tokens, for assertions.
  List<String> get dispositivos => _dispositivos.toList();

  /// Adds an unread alert on top, as if [lugarId] had just changed level.
  void emitir(int lugarId, NivelSaturacion anterior, NivelSaturacion nuevo) {
    final nombre = lugaresFake.firstWhere((l) => l.id == lugarId).nombre;
    _alertas.insert(
      0,
      Alerta(
        id: _siguienteId++,
        lugarId: lugarId,
        lugarNombre: nombre,
        nivelAnterior: anterior,
        nivelNuevo: nuevo,
        mensaje:
            '$nombre ahora está ${ChipSaturacion.etiquetaDe(nuevo)}. '
            'La saturación cambió de ${ChipSaturacion.etiquetaDe(anterior)} '
            'a ${ChipSaturacion.etiquetaDe(nuevo)}.',
        fechaHora: _reloj(),
      ),
    );
  }

  @override
  Future<PaginaAlertas> listar({int page = 1, int size = 20}) async {
    await _entrar();
    return PaginaAlertas(
      pagina: paginar(_alertas, page, size),
      noLeidas: _alertas.where((a) => !a.leida).length,
      mensaje: _alertas.isEmpty ? mensajeVacio : '',
    );
  }

  @override
  Future<void> marcarLeida(int id) async {
    await _entrar();
    final i = _alertas.indexWhere((a) => a.id == id);
    if (i < 0) {
      throw errorFake(404, 'ALERTA_NO_ENCONTRADA', 'Alerta no encontrada');
    }
    _alertas[i] = _leida(_alertas[i]);
  }

  @override
  Future<void> registrarDispositivo(
    String token,
    PlataformaPush plataforma,
  ) async {
    await _entrar();
    if (token.isEmpty || token.length > _tokenMaximo) {
      throw errorFake(
        400,
        'VALIDACION_FALLIDA',
        'El token debe tener entre 1 y $_tokenMaximo caracteres',
      );
    }
    _dispositivos.add(token);
  }

  @override
  Future<void> eliminarDispositivo(String token) async {
    await _entrar();
    _dispositivos.remove(token);
  }

  Future<void> _entrar() async {
    await _comportamiento.aplicar();
    if (_sesion != null && _sesion.token == null) {
      throw errorFake(401, 'NO_AUTENTICADO', 'No hay sesión activa');
    }
  }

  static Alerta _leida(Alerta a) => Alerta(
    id: a.id,
    lugarId: a.lugarId,
    lugarNombre: a.lugarNombre,
    nivelAnterior: a.nivelAnterior,
    nivelNuevo: a.nivelNuevo,
    mensaje: a.mensaje,
    leida: true,
    fechaHora: a.fechaHora,
  );
}
