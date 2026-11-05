import 'dart:async';

import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';

import '../logging/registro_errores.dart';
import '../map/tipos_mapa.dart';
import 'ubicacion_service.dart';

/// [UbicacionService] backed by `geolocator`. Asks for the permission the
/// first time; a refusal, disabled services or a failure return null.
class GeolocatorUbicacionService implements UbicacionService {
  /// Longest wait for a fresh fix before using the last known position.
  static const Duration limite = Duration(seconds: 10);

  final GeolocatorPlatform _plataforma;
  final RegistroErrores _registro;

  GeolocatorUbicacionService({
    GeolocatorPlatform? plataforma,
    RegistroErrores registro = const RegistroErroresConsola(),
  }) : _plataforma = plataforma ?? GeolocatorPlatform.instance,
       _registro = registro;

  @override
  Future<PuntoGeografico?> obtenerUbicacion() async {
    try {
      if (!await _plataforma.isLocationServiceEnabled()) return null;
      var permiso = await _plataforma.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await _plataforma.requestPermission();
      }
      if (permiso != LocationPermission.whileInUse &&
          permiso != LocationPermission.always) {
        return null;
      }
      return _punto(await _posicionActual());
    } catch (e, pila) {
      _registro.registrar('ubicacion.obtener', e, pila);
      return null;
    }
  }

  /// A fresh fix, or the last known position when none arrives in [limite].
  Future<Position?> _posicionActual() async {
    try {
      return await _plataforma.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: limite,
        ),
      );
    } on TimeoutException {
      return _plataforma.getLastKnownPosition();
    }
  }

  static PuntoGeografico? _punto(Position? p) =>
      p == null ? null : PuntoGeografico(p.latitude, p.longitude);
}
