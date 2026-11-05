import 'dart:async';

import 'package:crowdradar/core/location/geolocator_ubicacion_service.dart';
import 'package:crowdradar/core/map/tipos_mapa.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';

Position _posicion(double lat, double lng) => Position(
  latitude: lat,
  longitude: lng,
  timestamp: DateTime(2026, 11, 5),
  accuracy: 20,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

/// Scripted platform: each answer can be changed per test.
class _Plataforma extends GeolocatorPlatform {
  bool servicioActivo = true;
  LocationPermission permiso = LocationPermission.whileInUse;
  LocationPermission respuestaAlPedir = LocationPermission.whileInUse;
  Future<Position> Function() actual = () async => _posicion(-12.12, -77.03);
  Position? ultimaConocida;
  int pedidos = 0;
  LocationSettings? ajustes;

  @override
  Future<bool> isLocationServiceEnabled() async => servicioActivo;

  @override
  Future<LocationPermission> checkPermission() async => permiso;

  @override
  Future<LocationPermission> requestPermission() async {
    pedidos++;
    return respuestaAlPedir;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) {
    ajustes = locationSettings;
    return actual();
  }

  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async => ultimaConocida;
}

void main() {
  late _Plataforma plataforma;
  late GeolocatorUbicacionService servicio;

  setUp(() {
    plataforma = _Plataforma();
    servicio = GeolocatorUbicacionService(plataforma: plataforma);
  });

  test('a granted permission returns the current position', () async {
    expect(
      await servicio.obtenerUbicacion(),
      const PuntoGeografico(-12.12, -77.03),
    );
    expect(plataforma.pedidos, 0);
    expect(plataforma.ajustes?.timeLimit, GeolocatorUbicacionService.limite);
  });

  test('asks for the permission once and uses it when granted', () async {
    plataforma.permiso = LocationPermission.denied;

    expect(
      await servicio.obtenerUbicacion(),
      const PuntoGeografico(-12.12, -77.03),
    );
    expect(plataforma.pedidos, 1);
  });

  test('a refused permission returns null', () async {
    plataforma
      ..permiso = LocationPermission.denied
      ..respuestaAlPedir = LocationPermission.denied;

    expect(await servicio.obtenerUbicacion(), isNull);
  });

  test('a permanently refused permission returns null without asking', () async {
    plataforma.permiso = LocationPermission.deniedForever;

    expect(await servicio.obtenerUbicacion(), isNull);
    expect(plataforma.pedidos, 0);
  });

  test('location services turned off return null without asking', () async {
    plataforma.servicioActivo = false;

    expect(await servicio.obtenerUbicacion(), isNull);
    expect(plataforma.pedidos, 0);
  });

  test('no fix in time falls back to the last known position', () async {
    plataforma
      ..actual = (() => Future.error(TimeoutException('sin señal')))
      ..ultimaConocida = _posicion(-12.09, -77.05);

    expect(
      await servicio.obtenerUbicacion(),
      const PuntoGeografico(-12.09, -77.05),
    );
  });

  test('no fix and no last known position return null', () async {
    plataforma.actual = () => Future.error(TimeoutException('sin señal'));

    expect(await servicio.obtenerUbicacion(), isNull);
  });

  test('a platform failure returns null instead of throwing', () async {
    plataforma.actual = () => Future.error(StateError('plugin roto'));

    expect(await servicio.obtenerUbicacion(), isNull);
  });
}
