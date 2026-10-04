import '../../../core/models/analitica.dart';
import '../analitica_parametros.dart';
import '../comun/analitica_cubit.dart';
import '../data/analitica_repository.dart';

/// HU 6.2: weekdays against weekends over the last four weeks.
class CompararPeriodosCubit extends AnaliticaCubit<ComparacionPeriodos> {
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
      hasta.day - AnaliticaParametros.diasVentanaComparacion + 1,
    );
    return _repositorio.comparar(
      _lugarId,
      desdeA: desde,
      hastaA: hasta,
      desdeB: desde,
      hastaB: hasta,
      diasA: AnaliticaParametros.laborables,
      diasB: AnaliticaParametros.finDeSemana,
    );
  }

  @override
  bool estaVacio(ComparacionPeriodos datos) => datos.sinDatos;

  @override
  String? mensajeDe(ComparacionPeriodos datos) => datos.mensaje;
}
