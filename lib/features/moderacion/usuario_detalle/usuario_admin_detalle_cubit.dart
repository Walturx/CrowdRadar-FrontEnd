import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/moderacion.dart';
import '../../../core/utils/mensaje_error.dart';
import '../data/moderacion_repository.dart';
import 'usuario_admin_detalle_state.dart';

/// HU 7.2 c3, 7.3 and 7.4: one user with the suspend and reactivate actions.
class UsuarioAdminDetalleCubit extends Cubit<UsuarioAdminDetalleState> {
  /// Durations the admin can pick (the backend config is a subset of these).
  static const List<int> diasPermitidos = [3, 7, 30];
  static const int motivoMinimo = 10;
  static const int motivoMaximo = 280;
  static const String mensajeMotivoInvalido =
      'El motivo debe tener entre $motivoMinimo y $motivoMaximo caracteres.';

  final ModeracionRepository _repositorio;
  final int usuarioId;

  UsuarioAdminDetalleCubit(this._repositorio, this.usuarioId)
    : super(const UsuarioAdminDetalleCargando());

  Future<void> cargar() async {
    if (isClosed) return;
    emit(const UsuarioAdminDetalleCargando());
    try {
      final usuario = await _repositorio.usuario(usuarioId);
      if (isClosed) return;
      emit(UsuarioAdminDetalleCargado(usuario: usuario));
    } catch (e) {
      if (isClosed) return;
      emit(
        UsuarioAdminDetalleError(
          mensajeDeError(e),
          codigo: codigoDeError(e),
          esSinConexion: esErrorSinConexion(e),
        ),
      );
    }
  }

  /// HU 7.3: the confirmation dialog already ran; the rules are rechecked here.
  Future<void> suspender(int dias, String motivo) async {
    final actual = state;
    if (isClosed ||
        actual is! UsuarioAdminDetalleCargado ||
        actual.enCurso ||
        actual.usuario.estaSuspendido ||
        !diasPermitidos.contains(dias)) {
      return;
    }
    final texto = motivo.trim();
    if (texto.length < motivoMinimo || texto.length > motivoMaximo) {
      emit(
        UsuarioAdminDetalleCargado(
          usuario: actual.usuario,
          aviso: mensajeMotivoInvalido,
        ),
      );
      return;
    }
    emit(UsuarioAdminDetalleCargado(usuario: actual.usuario, enCurso: true));
    try {
      final sancion = await _repositorio.suspender(
        usuarioId,
        dias: dias,
        motivo: texto,
      );
      _terminar(
        _conEstado(actual.usuario, EstadoCuenta.suspendido, sancion),
        '${actual.usuario.nombreCompleto} no podrá publicar reportes durante '
        '${sancion.dias} días. Se le notificó el motivo.',
      );
    } catch (e) {
      await _fallar(actual.usuario, e, 'USUARIO_YA_SUSPENDIDO');
    }
  }

  /// HU 7.4 c2: the confirmation dialog already ran.
  Future<void> reactivar() async {
    final actual = state;
    if (isClosed ||
        actual is! UsuarioAdminDetalleCargado ||
        actual.enCurso ||
        !actual.usuario.estaSuspendido) {
      return;
    }
    emit(UsuarioAdminDetalleCargado(usuario: actual.usuario, enCurso: true));
    try {
      await _repositorio.reactivar(usuarioId);
      _terminar(
        _conEstado(actual.usuario, EstadoCuenta.activo, null),
        '${actual.usuario.nombreCompleto} recuperó el acceso y ya puede '
        'volver a publicar reportes.',
      );
    } catch (e) {
      await _fallar(actual.usuario, e, 'USUARIO_NO_SUSPENDIDO');
    }
  }

  void descartarAviso() {
    final actual = state;
    if (isClosed ||
        actual is! UsuarioAdminDetalleCargado ||
        actual.aviso == null) {
      return;
    }
    emit(UsuarioAdminDetalleCargado(usuario: actual.usuario));
  }

  void _terminar(DetalleUsuarioAdmin usuario, String aviso) {
    if (isClosed) return;
    emit(UsuarioAdminDetalleCargado(usuario: usuario, aviso: aviso));
  }

  /// Shows the failure; when it means the screen is stale ([codigoObsoleto])
  /// the user is reloaded first so the buttons match the server.
  Future<void> _fallar(
    DetalleUsuarioAdmin usuario,
    Object error,
    String codigoObsoleto,
  ) async {
    if (isClosed) return;
    var vigente = usuario;
    if (codigoDeError(error) == codigoObsoleto) {
      try {
        vigente = await _repositorio.usuario(usuarioId);
      } catch (_) {}
      if (isClosed) return;
    }
    emit(
      UsuarioAdminDetalleCargado(
        usuario: vigente,
        aviso: mensajeDeError(error),
      ),
    );
  }

  DetalleUsuarioAdmin _conEstado(
    DetalleUsuarioAdmin u,
    EstadoCuenta status,
    SancionVigente? sancion,
  ) => DetalleUsuarioAdmin(
    id: u.id,
    nombre: u.nombre,
    apellido: u.apellido,
    email: u.email,
    rol: u.rol,
    status: status,
    puntosKarma: u.puntosKarma,
    sancionVigente: sancion,
    reportesPublicados: u.reportesPublicados,
    reportesDenunciados: u.reportesDenunciados,
  );
}
