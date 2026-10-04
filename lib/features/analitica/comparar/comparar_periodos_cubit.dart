import '../../../core/models/analitica.dart';
import '../carga/analitica_cubit.dart';
import '../data/analitica_repository.dart';

/// HU 6.2: weekdays against weekends over the last four weeks.
class CompararPeriodosCubit extends AnaliticaCubit<ComparacionPeriodos> {
  static const int _diasVentana = 28;
  static const String _laborables = 'LABORABLES';
  static const String _finDeSemana = 'FIN_DE_SEMANA';

  final AnaliticaRepository _repositorio;
  final int _lugarId;
  final DateTime Function() _reloj;

  CompararPeriodosCubit(
    this._repositorio,
    this._lugarId, {
    DateTime Function()? reloj,
  }) : _reloj = reloj ?? DateTime.now;

  @override
  Future<ComparacionPeriodos> obtener() {
    final hoy = _reloj();
    final hasta = DateTime(hoy.year, hoy.month, hoy.day);
    final desde = DateTime(
      hasta.year,
      hasta.month,
      hasta.day - _diasVentana + 1,
    );
    return _repositorio.comparar(
      _lugarId,
      desdeA: desde,
      hastaA: hasta,
      desdeB: desde,
      hastaB: hasta,
      diasA: _laborables,
      diasB: _finDeSemana,
    );
  }

  @override
  bool estaVacio(ComparacionPeriodos datos) => datos.sinDatos;

  @override
  String? mensajeDe(ComparacionPeriodos datos) => datos.mensaje;
}
