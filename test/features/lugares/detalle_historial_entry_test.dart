import 'package:crowdradar/app/fakes/favorito_repository_fake.dart';
import 'package:crowdradar/app/fakes/reporte_repository_fake.dart';
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

import '../../fakes/enrutador_falso.dart';
import '../../fakes/lugar_repo_falso.dart';

void main() {
  testWidgets('Ver historial opens the place history (HU 6.1 c1)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    addTearDown(tester.view.resetPhysicalSize);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = RepoLugarFalso(
      alObtener: (_) async => const LugarDetalle(
        id: 1,
        nombre: 'Parque Kennedy',
        categoria: CategoriaLugar.parque,
        latitud: -12.1,
        longitud: -77.0,
        saturacion: SaturacionLugar(nivel: NivelSaturacion.moderado),
      ),
    );
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<LugarRepository>.value(value: repo),
          RepositoryProvider<FavoritoRepository>.value(
            value: FavoritoRepositoryFake(),
          ),
          RepositoryProvider<ReporteRepository>.value(
            value: ReporteRepositoryFake(),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: enrutadorDe(
            ruta: '/mapa/lugares/1',
            inicial: '/mapa/lugares/1',
            pantalla: const DetalleLugarPage(lugarId: 1),
            otras: const ['/mapa/lugares/1/historial'],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Ver historial'));
    await tester.pumpAndSettle();

    expect(find.text('RUTA /mapa/lugares/1/historial'), findsOneWidget);
  });
}
