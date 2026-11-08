import 'package:crowdradar/core/models/tier_usuario.dart';
import 'package:crowdradar/core/session/session_service.dart';
import 'package:crowdradar/core/session/usuario_sesion.dart';
import 'package:flutter_test/flutter_test.dart';

import 'datos_fake.dart';
import 'perfil_repository_fake.dart';

/// C1 thresholds (CRO-72), only to check the fake seeds are consistent; the
/// app itself never derives a tier from points.
TierUsuario _tierSegunC1(int puntos) => puntos >= 300
    ? TierUsuario.crowdRoyalty
    : puntos >= 150
    ? TierUsuario.crowdCollaborator
    : puntos >= 50
    ? TierUsuario.crowdExplorer
    : TierUsuario.crowdBaby;

void main() {
  late SessionService sesion;

  setUp(() async {
    sesion = SessionService.instance..reiniciar();
    await sesion.iniciar('t', const UsuarioSesion(id: 1));
  });
  tearDown(() => sesion.reiniciar());

  test('the profile fake returns the seeded points and tier', () async {
    final perfil = await PerfilRepositoryFake(sesion).obtener();

    expect(perfil.puntos, usuarioFake.puntos);
    expect(perfil.tier, usuarioFake.tier);
    expect(perfil.tier, TierUsuario.crowdExplorer);
  });

  test('editing the profile keeps the points and tier', () async {
    final repo = PerfilRepositoryFake(sesion);

    final editado = await repo.actualizar({'nombre': 'Beatriz'});

    expect(editado.nombre, 'Beatriz');
    expect(editado.puntos, usuarioFake.puntos);
    expect(editado.tier, usuarioFake.tier);
  });

  test('every fake account seeds a tier consistent with its points', () {
    for (final u in [usuarioFake, usuarioAdminFake]) {
      expect(u.tier, _tierSegunC1(u.puntos), reason: '${u.email}');
    }
  });
}
