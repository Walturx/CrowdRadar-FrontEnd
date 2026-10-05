import '../../core/models/categoria_lugar.dart';
import '../../core/models/nivel_saturacion.dart';
import '../../core/models/validacion.dart';
import '../../core/network/respuesta_api.dart';
import '../../core/session/session_service.dart';
import '../../features/validacion/data/validacion_repository.dart';
import 'comportamiento_fake.dart';
import 'datos_fake.dart';
import 'karma_fake.dart';

/// In-memory validation with the backend rules: own reports cannot be voted or
/// reported (422), a second vote or report is a 409, a vote is worth +2 karma
/// and fewer than 3 votes is `INSUFICIENTE`. Votes weigh 1 here (the real
/// backend weighs them by karma).
class ValidacionRepositoryFake implements ValidacionRepository {
  static const int idReportePropio = 103;
  static const int _karmaPorValidacion = 2;
  static const int _minVotos = 3;
  static const double _umbralAlta = 70;
  static const double _umbralMedia = 40;
  static const String _advertenciaBaja =
      'Este reporte tiene pocas confirmaciones. Tómalo con precaución.';

  final ComportamientoFake _comportamiento;
  final KarmaFake _karma;

  /// When given, every call needs a signed-in session like the real backend.
  final SessionService? _sesion;

  ValidacionRepositoryFake({
    ComportamientoFake comportamiento = const ComportamientoFake(),
    KarmaFake? karma,
    SessionService? sesion,
  }) : _comportamiento = comportamiento,
       _sesion = sesion,
       _karma = karma ?? KarmaFake();

  final List<_ReporteFake> _reportes = [
    _ReporteFake(
      101,
      'Parque Kennedy',
      CategoriaLugar.parque,
      NivelSaturacion.saturado,
      400,
      18,
      3,
    ),
    _ReporteFake(
      102,
      'Mercado de Surquillo',
      CategoriaLugar.mercado,
      NivelSaturacion.moderado,
      1200,
      1,
      1,
    ),
    _ReporteFake(
      104,
      'Plaza de Armas',
      CategoriaLugar.plaza,
      NivelSaturacion.tranquilo,
      2500,
      5,
      8,
    ),
    _ReporteFake(
      idReportePropio,
      'Parque Kennedy',
      CategoriaLugar.parque,
      NivelSaturacion.moderado,
      400,
      2,
      1,
      propio: true,
    ),
  ];

  @override
  Future<Pagina<ReportePendiente>> pendientes({
    required double lat,
    required double lng,
    double radioKm = 5,
    int horas = 3,
    int page = 1,
    int size = 20,
  }) async {
    await _entrar();
    final visibles = _reportes.where((r) => !r.propio && r.mio == null);
    return paginar([for (final r in visibles) _pendiente(r)], page, size);
  }

  @override
  Future<DetalleReporte> obtenerReporte(int reporteId) async {
    await _entrar();
    final r = _buscar(reporteId);
    return DetalleReporte(
      id: r.id,
      lugar: r.lugar,
      nivel: r.nivel,
      fechaHora: r.fechaHora,
      confiabilidad: r.confiabilidad,
      estadoValidacion: r.estado,
      miValidacion: r.mio,
      yaDenunciado: r.denunciado,
      esPropio: r.propio,
    );
  }

  @override
  Future<Confiabilidad> confiabilidad(int reporteId) async {
    await _entrar();
    return _buscar(reporteId).confiabilidad;
  }

  @override
  Future<ResultadoVoto> validar(
    int reporteId,
    TipoAccionValidacion accion,
  ) async {
    await _entrar();
    final r = _buscar(reporteId);
    if (r.propio) {
      throw errorFake(
        422,
        'AUTOVALIDACION_NO_PERMITIDA',
        'No puedes validar tu propio reporte',
      );
    }
    if (r.mio != null) {
      throw errorFake(409, 'VALIDACION_DUPLICADA', 'Ya validaste este reporte');
    }
    r.mio = accion;
    if (accion == TipoAccionValidacion.confirmar) {
      r.confirmaciones++;
    } else {
      r.rechazos++;
    }
    _karma.total += _karmaPorValidacion;
    return ResultadoVoto(
      accion: accion,
      puntosGanados: _karmaPorValidacion,
      totalKarma: _karma.total,
      confiabilidad: r.confiabilidad,
      estadoValidacion: r.estado,
    );
  }

  @override
  Future<Pagina<EstadoReporteValidacion>> estadoMisReportes({
    int page = 1,
    int size = 20,
  }) async {
    await _entrar();
    return paginar(
      [
        for (final r in _reportes.where((r) => r.propio))
          EstadoReporteValidacion(
            reporteId: r.id,
            lugar: r.lugar,
            nivel: r.nivel,
            fechaHora: r.fechaHora,
            confiabilidad: r.confiabilidad,
            estadoValidacion: r.estado,
          ),
      ],
      page,
      size,
    );
  }

  @override
  Future<void> denunciar(
    int reporteId,
    MotivoDenuncia motivo, {
    String? detalle,
  }) async {
    await _entrar();
    final r = _buscar(reporteId);
    if (r.propio) {
      throw errorFake(
        422,
        'AUTODENUNCIA_NO_PERMITIDA',
        'No puedes denunciar tu propio reporte',
      );
    }
    if (motivo == MotivoDenuncia.otro && (detalle ?? '').trim().isEmpty) {
      throw errorFake(400, 'VALIDACION_FALLIDA', 'Datos inválidos.');
    }
    if (r.denunciado) {
      throw errorFake(
        409,
        'DENUNCIA_DUPLICADA',
        'Esta denuncia ya fue registrada.',
      );
    }
    r.denunciado = true;
  }

  Future<void> _entrar() async {
    await _comportamiento.aplicar();
    if (_sesion != null && _sesion.token == null) {
      throw errorFake(401, 'NO_AUTENTICADO', 'No hay sesión activa');
    }
  }

  ReportePendiente _pendiente(_ReporteFake r) => ReportePendiente(
    id: r.id,
    lugar: r.lugar,
    nivel: r.nivel,
    fechaHora: r.fechaHora,
    distanciaMetros: r.distancia,
    confiabilidad: r.confiabilidad,
  );

  _ReporteFake _buscar(int id) => _reportes.firstWhere(
    (r) => r.id == id,
    orElse: () =>
        throw errorFake(404, 'REPORTE_NO_ENCONTRADO', 'Reporte no encontrado'),
  );
}

class _ReporteFake {
  final int id;
  final LugarReporte lugar;
  final NivelSaturacion nivel;
  final int distancia;
  final bool propio;
  final DateTime fechaHora = DateTime.now();
  int confirmaciones;
  int rechazos;
  TipoAccionValidacion? mio;
  bool denunciado = false;

  _ReporteFake(
    this.id,
    String lugarNombre,
    CategoriaLugar categoria,
    this.nivel,
    this.distancia,
    this.confirmaciones,
    this.rechazos, {
    this.propio = false,
  }) : lugar = LugarReporte(
         id: id - 100,
         nombre: lugarNombre,
         categoria: categoria,
       );

  int get _total => confirmaciones + rechazos;

  Confiabilidad get confiabilidad {
    if (_total < ValidacionRepositoryFake._minVotos) {
      return Confiabilidad(
        porcentaje: null,
        nivel: NivelConfiabilidad.insuficiente,
        confirmaciones: confirmaciones,
        rechazos: rechazos,
      );
    }
    final pct = double.parse(
      (100 * confirmaciones / _total).toStringAsFixed(2),
    );
    final nivel = pct >= ValidacionRepositoryFake._umbralAlta
        ? NivelConfiabilidad.alta
        : pct >= ValidacionRepositoryFake._umbralMedia
        ? NivelConfiabilidad.media
        : NivelConfiabilidad.baja;
    return Confiabilidad(
      porcentaje: pct,
      nivel: nivel,
      confirmaciones: confirmaciones,
      rechazos: rechazos,
      advertencia: nivel == NivelConfiabilidad.baja
          ? ValidacionRepositoryFake._advertenciaBaja
          : null,
    );
  }

  EstadoValidacion get estado => _total == 0
      ? EstadoValidacion.sinValidaciones
      : _total >= 10 && confiabilidad.nivel == NivelConfiabilidad.alta
      ? EstadoValidacion.validado
      : _total >= 10 && confiabilidad.nivel == NivelConfiabilidad.baja
      ? EstadoValidacion.rechazado
      : EstadoValidacion.enValidacion;
}
