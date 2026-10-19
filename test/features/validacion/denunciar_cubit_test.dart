import 'dart:async';

import 'package:crowdradar/core/models/validacion.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/features/validacion/data/validacion_repository.dart';
import 'package:crowdradar/features/validacion/denunciar/denunciar_cubit.dart';
import 'package:crowdradar/features/validacion/denunciar/denunciar_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/errores_comunes.dart';

class _MockRepo extends Mock implements ValidacionRepository {}

ApiException _api(int status, String code, [String msg = 'mensaje del API']) =>
    ApiException(status: status, message: msg, code: code);

void main() {
  late _MockRepo repo;
  late DenunciarCubit cubit;

  setUpAll(() => registerFallbackValue(MotivoDenuncia.spam));
  setUp(() {
    repo = _MockRepo();
    cubit = DenunciarCubit(repo, 31);
  });

  void stubOk() => when(
    () => repo.denunciar(31, any(), detalle: any(named: 'detalle')),
  ).thenAnswer((_) async {});

  test('429 keeps the form with the wait message', () async {
    when(
      () => repo.denunciar(31, any(), detalle: any(named: 'detalle')),
    ).thenThrow(
      const ApiException(
        status: 429,
        message: 'x',
        code: 'DEMASIADAS_SOLICITUDES',
        reintentarEnSegundos: 3600,
      ),
    );

    await cubit.enviar(MotivoDenuncia.spam, '');

    expect(
      cubit.state,
      const DenunciarFormulario(
        error: 'Demasiadas acciones seguidas, probá en 60 minutos',
      ),
    );
  });

  test('without a motivo it explains and does not call the API', () async {
    await cubit.enviar(null, '');

    expect(
      cubit.state,
      const DenunciarFormulario(error: DenunciarCubit.errorSinMotivo),
    );
    verifyNever(
      () => repo.denunciar(any(), any(), detalle: any(named: 'detalle')),
    );
  });

  test('OTRO needs a description and at most 280 characters', () async {
    await cubit.enviar(MotivoDenuncia.otro, '   ');
    expect(
      cubit.state,
      const DenunciarFormulario(error: DenunciarCubit.errorSinDetalle),
    );

    await cubit.enviar(MotivoDenuncia.otro, 'x' * 281);
    expect(
      cubit.state,
      const DenunciarFormulario(error: DenunciarCubit.errorDetalleLargo),
    );
    verifyNever(
      () => repo.denunciar(any(), any(), detalle: any(named: 'detalle')),
    );
  });

  test('a valid report is sent and ends as Enviado', () async {
    stubOk();

    await cubit.enviar(MotivoDenuncia.informacionFalsa, 'ignored');

    expect(cubit.state, const DenunciarEnviado());
    verify(
      () => repo.denunciar(31, MotivoDenuncia.informacionFalsa, detalle: null),
    ).called(1);
  });

  test('OTRO sends the trimmed description', () async {
    stubOk();

    await cubit.enviar(MotivoDenuncia.otro, '  mentira  ');

    verify(
      () => repo.denunciar(31, MotivoDenuncia.otro, detalle: 'mentira'),
    ).called(1);
  });

  test('409 is blocking: "ya fue registrada"', () async {
    when(
      () => repo.denunciar(31, any(), detalle: any(named: 'detalle')),
    ).thenThrow(_api(409, 'DENUNCIA_DUPLICADA'));

    await cubit.enviar(MotivoDenuncia.spam, '');

    expect(
      cubit.state,
      const DenunciarBloqueado(DenunciarCubit.mensajeYaRegistrada),
    );
  });

  test('404 and 422 are blocking with the server message', () async {
    when(
      () => repo.denunciar(31, any(), detalle: any(named: 'detalle')),
    ).thenThrow(_api(422, 'AUTODENUNCIA_NO_PERMITIDA', 'Es tu reporte'));

    await cubit.enviar(MotivoDenuncia.spam, '');

    expect(cubit.state, const DenunciarBloqueado('Es tu reporte'));
  });

  test(
    'a network failure goes back to the form so the user can retry',
    () async {
      when(
        () => repo.denunciar(31, any(), detalle: any(named: 'detalle')),
      ).thenThrow(const ApiException.sinConexion());

      await cubit.enviar(MotivoDenuncia.spam, '');

      expect(
        cubit.state,
        isA<DenunciarFormulario>().having((s) => s.error, 'error', isNotNull),
      );
      expect((cubit.state as DenunciarFormulario).enviando, isFalse);
    },
  );

  test('a second send while one is in flight is ignored', () async {
    final espera = Completer<void>();
    when(
      () => repo.denunciar(31, any(), detalle: any(named: 'detalle')),
    ).thenAnswer((_) => espera.future);

    final a = cubit.enviar(MotivoDenuncia.spam, '');
    expect((cubit.state as DenunciarFormulario).enviando, isTrue);
    final b = cubit.enviar(MotivoDenuncia.spam, '');
    espera.complete();
    await Future.wait([a, b]);

    verify(
      () => repo.denunciar(31, any(), detalle: any(named: 'detalle')),
    ).called(1);
  });

  test('closing while sending does not emit', () async {
    final espera = Completer<void>();
    when(
      () => repo.denunciar(31, any(), detalle: any(named: 'detalle')),
    ).thenAnswer((_) => espera.future);

    final f = cubit.enviar(MotivoDenuncia.spam, '');
    await cubit.close();
    espera.complete();

    await expectLater(f, completes);
  });

  group('common errors', () {
    testErroresComunes('a failure is not blocking: back to the form', (
      caso,
    ) async {
      when(
        () => repo.denunciar(31, any(), detalle: any(named: 'detalle')),
      ).thenThrow(caso.error);

      await cubit.enviar(MotivoDenuncia.spam, '');

      expect(cubit.state, DenunciarFormulario(error: caso.mensaje));
      stubOk();
      await cubit.enviar(MotivoDenuncia.spam, '');
      expect(cubit.state, const DenunciarEnviado());
    });

    for (final status in [500, 502, 503]) {
      test('$status falls back to the form with the server message', () async {
        when(
          () => repo.denunciar(31, any(), detalle: any(named: 'detalle')),
        ).thenThrow(_api(status, 'ERROR_INTERNO', 'Servidor no disponible'));

        await cubit.enviar(MotivoDenuncia.spam, '');

        expect(
          cubit.state,
          const DenunciarFormulario(error: 'Servidor no disponible'),
        );
      });
    }
  });
}
