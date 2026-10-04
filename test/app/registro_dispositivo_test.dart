import 'dart:async';

import 'package:crowdradar/app/fakes/alerta_repository_fake.dart';
import 'package:crowdradar/app/registro_dispositivo.dart';
import 'package:crowdradar/core/logging/registro_errores.dart';
import 'package:crowdradar/core/network/api_exception.dart';
import 'package:crowdradar/core/push/receptor_push.dart';
import 'package:crowdradar/features/alertas/data/alerta_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _Receptor implements ReceptorPush {
  String? token;

  _Receptor(this.token);

  @override
  Future<void> inicializar() async {}

  @override
  Future<String?> obtenerToken() async => token;

  @override
  Stream<int> get lugarAbierto => const Stream<int>.empty();
}

/// Records the device calls and can be told to fail them.
class _Alertas extends AlertaRepositoryFake {
  final List<String> llamadas = [];
  PlataformaPush? plataforma;
  Object? error;

  _Alertas() : super(sembrar: false);

  @override
  Future<void> registrarDispositivo(String token, PlataformaPush p) async {
    llamadas.add('registrar:$token');
    plataforma = p;
    if (error != null) throw error!;
    return super.registrarDispositivo(token, p);
  }

  @override
  Future<void> eliminarDispositivo(String token) async {
    llamadas.add('eliminar:$token');
    if (error != null) throw error!;
    return super.eliminarDispositivo(token);
  }
}

class _Registro implements RegistroErrores {
  final List<String> contextos = [];

  @override
  void registrar(String contexto, Object error, [StackTrace? pila]) =>
      contextos.add(contexto);
}

void main() {
  late _Alertas alertas;
  late _Registro registro;

  RegistroDispositivo crear(
    String? token, {
    PlataformaPush plataforma = PlataformaPush.android,
  }) => RegistroDispositivo(
    receptor: _Receptor(token),
    alertas: alertas,
    plataforma: plataforma,
    registro: registro,
  );

  setUp(() {
    alertas = _Alertas();
    registro = _Registro();
  });

  group('registrar', () {
    test('sends the device token with the platform', () async {
      await crear('tok-1', plataforma: PlataformaPush.ios).registrar();

      expect(alertas.llamadas, ['registrar:tok-1']);
      expect(alertas.plataforma, PlataformaPush.ios);
      expect(alertas.dispositivos, ['tok-1']);
    });

    test('without a token it skips silently', () async {
      await crear(null).registrar();

      expect(alertas.llamadas, isEmpty);
      expect(registro.contextos, isEmpty);
    });

    test('a failure is logged and never thrown', () async {
      alertas.error = const ApiException.sinConexion();

      await expectLater(crear('tok-1').registrar(), completes);

      expect(registro.contextos, ['RegistroDispositivo.registrar']);
    });
  });

  group('quitar', () {
    test('deletes the token that was registered', () async {
      final r = crear('tok-1');
      await r.registrar();

      await r.quitar();

      expect(alertas.llamadas, ['registrar:tok-1', 'eliminar:tok-1']);
      expect(alertas.dispositivos, isEmpty);
    });

    test('does nothing when nothing was registered, and only once', () async {
      final r = crear('tok-1');
      await r.quitar();
      expect(alertas.llamadas, isEmpty);

      await r.registrar();
      await r.quitar();
      await r.quitar();

      expect(alertas.llamadas.where((l) => l.startsWith('eliminar')), hasLength(1));
    });

    test('a failure is logged and never thrown', () async {
      final r = crear('tok-1');
      await r.registrar();
      alertas.error = const ApiException(status: 401, message: 'x');

      await expectLater(r.quitar(), completes);

      expect(registro.contextos, ['RegistroDispositivo.quitar']);
    });
  });
}
