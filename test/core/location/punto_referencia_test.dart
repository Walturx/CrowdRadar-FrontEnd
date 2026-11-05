import 'dart:async';

import 'package:crowdradar/core/location/punto_referencia.dart';
import 'package:crowdradar/core/map/centro_compartido.dart';
import 'package:crowdradar/core/map/tipos_mapa.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/ubicacion_fake.dart';

void main() {
  late UbicacionServiceFake ubicacion;
  late CentroMapaCompartido centroMapa;
  late PuntoReferencia referencia;

  setUp(() {
    ubicacion = UbicacionServiceFake();
    centroMapa = CentroMapaCompartido();
    referencia = PuntoReferencia(ubicacion, centroMapa);
  });

  test('before asking, the map centre is the reference', () {
    expect(
      referencia.actual,
      const Referencia(CentroMapaCompartido.lima, OrigenReferencia.centroMapa),
    );
    expect(referencia.dispositivo, isNull);
  });

  test('a known device location is the reference', () async {
    ubicacion.punto = miraflores;

    final r = await referencia.actualizar();

    expect(r, const Referencia(miraflores, OrigenReferencia.dispositivo));
    expect(referencia.actual, r);
    expect(referencia.dispositivo, miraflores);
  });

  test('without the device location the last map centre is used', () async {
    centroMapa.actualizar(
      const LimitesMapa(norte: -12, sur: -13, este: -76, oeste: -77),
    );

    final r = await referencia.actualizar();

    expect(
      r,
      const Referencia(
        PuntoGeografico(-12.5, -76.5),
        OrigenReferencia.centroMapa,
      ),
    );
  });

  test('a location that stops being available falls back again', () async {
    ubicacion.punto = miraflores;
    await referencia.actualizar();
    ubicacion.punto = null;

    final r = await referencia.actualizar();

    expect(r.origen, OrigenReferencia.centroMapa);
    expect(referencia.dispositivo, isNull);
  });

  test('overlapping calls share one location request', () async {
    ubicacion.pendiente = Completer();

    final a = referencia.actualizar();
    final b = referencia.actualizar();
    ubicacion.pendiente!.complete(miraflores);

    expect(await a, await b);
    expect(ubicacion.llamadas, 1);

    ubicacion.pendiente = null;
    await referencia.actualizar();
    expect(ubicacion.llamadas, 2);
  });
}
