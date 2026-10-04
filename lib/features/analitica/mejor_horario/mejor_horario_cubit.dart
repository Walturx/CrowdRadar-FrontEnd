import '../../../core/models/analitica.dart';
import '../carga/analitica_cubit.dart';
import '../data/analitica_repository.dart';

class MejorHorarioCubit extends AnaliticaCubit<MejorHorario> {
  final AnaliticaRepository _repositorio;
  final int _lugarId;

  MejorHorarioCubit(this._repositorio, this._lugarId);

  @override
  Future<MejorHorario> obtener() => _repositorio.mejorHorario(_lugarId);

  @override
  bool estaVacio(MejorHorario datos) => datos.sinDatos || datos.franjas.isEmpty;

  @override
  String? mensajeDe(MejorHorario datos) => datos.mensaje;
}
