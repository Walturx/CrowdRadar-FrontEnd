import 'package:crowdradar/core/map/tipos_mapa.dart';
import 'package:crowdradar/core/models/categoria_lugar.dart';
import 'package:crowdradar/core/models/lugar_detalle.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/features/favoritos/data/favorito_repository.dart';
import 'package:crowdradar/features/lugares/data/lugar_repository.dart';
import 'package:crowdradar/features/lugares/detalle/detalle_lugar_page.dart';
import 'package:crowdradar/features/reportes/data/reporte_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/favorito_repository_fake.dart';
import '../fakes/lugar_repo_falso.dart';
import '../fakes/reporte_repository_fake.dart';
import 'golden_harness.dart';

/// About 400 m from the place, so a distance is shown.
const _origin = PuntoGeografico(-12.1219, -77.0268);

/// A place at [level], updated 4 minutes ago (10 s margin keeps "hace 4 min"
/// stable while the test runs).
LugarDetalle _detail(NivelSaturacion level) => LugarDetalle(
  id: 1,
  nombre: 'Parque Kennedy',
  categoria: CategoriaLugar.parque,
  direccion: 'Av. Larco 345, Miraflores',
  latitud: -12.1219,
  longitud: -77.0297,
  abiertoAhora: true,
  horarioAtencion: '06:00 - 22:00',
  saturacion: SaturacionLugar(
    nivel: level,
    actualizadoEn: level == NivelSaturacion.sinInformacion
        ? null
        : DateTime.now().subtract(const Duration(minutes: 4, seconds: 10)),
    reportesRecientes: level == NivelSaturacion.sinInformacion ? 0 : 18,
  ),
);

void main() {
  Future<void> open(WidgetTester tester, NivelSaturacion level) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<LugarRepository>.value(
            value: RepoLugarFalso(alObtener: (_) async => _detail(level)),
          ),
          RepositoryProvider<FavoritoRepository>.value(
            value: FavoritoRepositoryFake(),
          ),
          RepositoryProvider<ReporteRepository>.value(
            value: ReporteRepositoryFake(),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: appTheme,
          builder: withoutAnimations,
          home: const DetalleLugarPage(lugarId: 1, origenDistancia: _origin),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await loadImages(tester);
  }

  for (final level in NivelSaturacion.values) {
    testWidgets('place detail, ${level.name}', (tester) async {
      await open(tester, level);

      expect(find.text('Parque Kennedy'), findsWidgets);
      await matchBaseline('detalle_${level.name}');
    });
  }
}
