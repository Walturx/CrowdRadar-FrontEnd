import '../../../core/models/analitica.dart';
import '../analitica_parametros.dart';
import '../carga/analitica_cubit.dart';
import '../data/analitica_repository.dart';

class HistorialLugarCubit extends AnaliticaCubit<SerieSaturacion> {
  final AnaliticaRepository _repositorio;
  final int _lugarId;
  final DateTime Function() _reloj;

  HistorialLugarCubit(
    this._repositorio,
    this._lugarId, {
    DateTime Function()? reloj,
  }) : _reloj = reloj ?? DateTime.now;

  AgrupacionHistorial _agrupacion = AgrupacionHistorial.hora;

  AgrupacionHistorial get agrupacion => _agrupacion;

  /// Hourly view = today (backend default); daily view = the short window.
  Future<void> seleccionar(AgrupacionHistorial agrupacion) async {
    if (enVuelo || agrupacion == _agrupacion) return;
    _agrupacion = agrupacion;
    await cargar();
  }

  @override
  Future<SerieSaturacion> obtener() {
    final hoy = _reloj();
    final fin = DateTime(hoy.year, hoy.month, hoy.day);
    final porDia = _agrupacion == AgrupacionHistorial.dia;
    return _repositorio.historial(
      _lugarId,
      desde: porDia
          ? DateTime(
              fin.year,
              fin.month,
              fin.day - (AnaliticaParametros.diasHistorialCorto - 1),
            )
          : null,
      hasta: porDia ? fin : null,
      agrupacion: _agrupacion,
    );
  }

  @override
  bool estaVacio(SerieSaturacion datos) =>
      datos.sinDatos || datos.puntos.isEmpty;

  @override
  String? mensajeDe(SerieSaturacion datos) => datos.mensaje;
}
