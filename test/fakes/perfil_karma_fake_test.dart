import 'package:crowdradar/app/fakes/karma_fake.dart';
import 'package:crowdradar/app/fakes/perfil_repository_fake.dart';
import 'package:crowdradar/app/fakes/reporte_repository_fake.dart';
import 'package:crowdradar/core/models/nivel_saturacion.dart';
import 'package:crowdradar/core/session/session_service.dart';
import 'package:crowdradar/core/session/usuario_sesion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'the profile fake reflects karma earned through the report fake',
    () async {
      final sesion = SessionService.instance..reiniciar();
      addTearDown(sesion.reiniciar);
      final karma = KarmaFake(100);
      final perfil = PerfilRepositoryFake(sesion, karma: karma);
      final reportes = ReporteRepositoryFake(karma: karma);
      await sesion.iniciar('t', const UsuarioSesion(id: 1));

      expect((await perfil.obtener()).puntosKarma, 100);
      await reportes.reportar(1, NivelSaturacion.moderado);

      expect((await perfil.obtener()).puntosKarma, 110);
    },
  );
}
