import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:crowdradar/core/models/moderacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/features/moderacion/data/moderacion_repository.dart';
import 'package:crowdradar/features/moderacion/usuario_detalle/usuario_admin_detalle_cubit.dart';
import 'package:crowdradar/features/moderacion/usuario_detalle/usuario_admin_detalle_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'json_moderacion.dart';

class _MockRepo extends Mock implements ModeracionRepository {}

final _activo = DetalleUsuarioAdmin.fromJson(detalleUsuarioJson());
final _suspendido = DetalleUsuarioAdmin.fromJson(
  detalleUsuarioJson(status: 'SUSPENDIDO', sancion: sancionJson()),
);
final _sancion = SancionVigente.fromJson(sancionJson());

ApiException _api(int status, String code, [String msg = 'mensaje del API']) =>
    ApiException(status: status, message: msg, code: code);

const _motivo = 'Spam reiterado en reportes';

void main() {
  late _MockRepo repo;

  setUp(() => repo = _MockRepo());

  UsuarioAdminDetalleCubit cubit() => UsuarioAdminDetalleCubit(repo, 12);

  Future<UsuarioAdminDetalleCubit> cargado(DetalleUsuarioAdmin u) async {
    when(() => repo.usuario(12)).thenAnswer((_) async => u);
    final c = cubit();
    await c.cargar();
    return c;
  }

  group('cargar', () {
    blocTest<UsuarioAdminDetalleCubit, UsuarioAdminDetalleState>(
      'loads the user with the report counters',
      setUp: () =>
          when(() => repo.usuario(12)).thenAnswer((_) async => _activo),
      build: cubit,
      act: (c) => c.cargar(),
      expect: () => [
        const UsuarioAdminDetalleCargando(),
        UsuarioAdminDetalleCargado(usuario: _activo),
      ],
    );

    blocTest<UsuarioAdminDetalleCubit, UsuarioAdminDetalleState>(
      '404 USUARIO_NO_ENCONTRADO is an error with the code',
      setUp: () => when(
        () => repo.usuario(12),
      ).thenThrow(_api(404, 'USUARIO_NO_ENCONTRADO', 'Usuario no encontrado')),
      build: cubit,
      act: (c) => c.cargar(),
      expect: () => [
        const UsuarioAdminDetalleCargando(),
        const UsuarioAdminDetalleError(
          'Usuario no encontrado',
          codigo: 'USUARIO_NO_ENCONTRADO',
        ),
      ],
    );
  });

  group('suspender (HU 7.3)', () {
    test('sends dias and motivo and shows the user as suspended', () async {
      final c = await cargado(_activo);
      when(
        () => repo.suspender(12, dias: 7, motivo: _motivo),
      ).thenAnswer((_) async => _sancion);

      await c.suspender(7, _motivo);

      verify(() => repo.suspender(12, dias: 7, motivo: _motivo)).called(1);
      final s = c.state as UsuarioAdminDetalleCargado;
      expect(s.usuario.estaSuspendido, isTrue);
      expect(s.usuario.sancionVigente, _sancion);
      expect(s.enCurso, isFalse);
      expect(
        s.aviso,
        'Lucia Paredes no podrá publicar reportes durante 7 días. '
        'Se le notificó el motivo.',
      );
      await c.close();
    });

    test('marks the action in flight and ignores a second call', () async {
      final c = await cargado(_activo);
      final respuesta = Completer<SancionVigente>();
      when(
        () => repo.suspender(12, dias: 7, motivo: _motivo),
      ).thenAnswer((_) => respuesta.future);

      final a = c.suspender(7, _motivo);
      final b = c.suspender(7, _motivo);
      expect((c.state as UsuarioAdminDetalleCargado).enCurso, isTrue);
      respuesta.complete(_sancion);
      await Future.wait([a, b]);

      verify(() => repo.suspender(12, dias: 7, motivo: _motivo)).called(1);
      await c.close();
    });

    test(
      'a short motivo or a dias outside 3/7/30 never reaches the API',
      () async {
        final c = await cargado(_activo);

        await c.suspender(7, 'corto');
        expect(
          (c.state as UsuarioAdminDetalleCargado).aviso,
          UsuarioAdminDetalleCubit.mensajeMotivoInvalido,
        );
        c.descartarAviso();
        await c.suspender(5, _motivo);

        verifyNever(
          () => repo.suspender(
            any(),
            dias: any(named: 'dias'),
            motivo: any(named: 'motivo'),
          ),
        );
        await c.close();
      },
    );

    test('ignores suspending an already suspended account', () async {
      final c = await cargado(_suspendido);

      await c.suspender(7, _motivo);

      verifyNever(
        () => repo.suspender(
          any(),
          dias: any(named: 'dias'),
          motivo: any(named: 'motivo'),
        ),
      );
      await c.close();
    });

    test(
      '409 USUARIO_YA_SUSPENDIDO refreshes the detail with the notice',
      () async {
        final c = await cargado(_activo);
        when(
          () => repo.suspender(12, dias: 7, motivo: _motivo),
        ).thenThrow(_api(409, 'USUARIO_YA_SUSPENDIDO', 'Ya suspendido'));
        when(() => repo.usuario(12)).thenAnswer((_) async => _suspendido);

        await c.suspender(7, _motivo);

        final s = c.state as UsuarioAdminDetalleCargado;
        expect(s.usuario.estaSuspendido, isTrue);
        expect(s.aviso, 'Ya suspendido');
        expect(s.enCurso, isFalse);
        await c.close();
      },
    );

    test(
      '422 OPERACION_NO_PERMITIDA keeps the user and shows the message',
      () async {
        final c = await cargado(_activo);
        when(
          () => repo.suspender(12, dias: 7, motivo: _motivo),
        ).thenThrow(_api(422, 'OPERACION_NO_PERMITIDA', 'No permitido'));

        await c.suspender(7, _motivo);

        final s = c.state as UsuarioAdminDetalleCargado;
        expect(s.usuario, _activo);
        expect(s.aviso, 'No permitido');
        expect(s.enCurso, isFalse);
        await c.close();
      },
    );

    test('an offline failure keeps the user and allows a retry', () async {
      final c = await cargado(_activo);
      when(
        () => repo.suspender(12, dias: 7, motivo: _motivo),
      ).thenThrow(const ApiException.sinConexion());

      await c.suspender(7, _motivo);

      final s = c.state as UsuarioAdminDetalleCargado;
      expect(s.usuario.estaSuspendido, isFalse);
      expect(s.aviso, ApiException.mensajeSinConexion);
      expect(s.enCurso, isFalse);
      await c.close();
    });

    test('closing while the request is in flight never emits', () async {
      final c = await cargado(_activo);
      final respuesta = Completer<SancionVigente>();
      when(
        () => repo.suspender(12, dias: 7, motivo: _motivo),
      ).thenAnswer((_) => respuesta.future);

      final futuro = c.suspender(7, _motivo);
      await c.close();
      respuesta.complete(_sancion);

      await expectLater(futuro, completes);
    });
  });

  group('reactivar (HU 7.4)', () {
    test('reactivates and clears the sancion', () async {
      final c = await cargado(_suspendido);
      when(() => repo.reactivar(12)).thenAnswer((_) async {});

      await c.reactivar();

      final s = c.state as UsuarioAdminDetalleCargado;
      expect(s.usuario.estaSuspendido, isFalse);
      expect(s.usuario.sancionVigente, isNull);
      expect(
        s.aviso,
        'Lucia Paredes recuperó el acceso y ya puede volver a publicar reportes.',
      );
      await c.close();
    });

    test('ignores reactivating an active account', () async {
      final c = await cargado(_activo);

      await c.reactivar();

      verifyNever(() => repo.reactivar(any()));
      await c.close();
    });

    test('409 USUARIO_NO_SUSPENDIDO refreshes the detail', () async {
      final c = await cargado(_suspendido);
      when(
        () => repo.reactivar(12),
      ).thenThrow(_api(409, 'USUARIO_NO_SUSPENDIDO', 'No suspendido'));
      when(() => repo.usuario(12)).thenAnswer((_) async => _activo);

      await c.reactivar();

      final s = c.state as UsuarioAdminDetalleCargado;
      expect(s.usuario.estaSuspendido, isFalse);
      expect(s.aviso, 'No suspendido');
      await c.close();
    });

    test('a failure keeps the account suspended with the notice', () async {
      final c = await cargado(_suspendido);
      when(() => repo.reactivar(12)).thenThrow(_api(500, 'X', 'Falló'));

      await c.reactivar();

      final s = c.state as UsuarioAdminDetalleCargado;
      expect(s.usuario.estaSuspendido, isTrue);
      expect(s.aviso, 'Falló');
      expect(s.enCurso, isFalse);
      await c.close();
    });
  });
}
