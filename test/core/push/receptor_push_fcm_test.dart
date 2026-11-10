// HU 8.3: the FCM receiver hands its token to the device registration (S1) and
// turns a notification tap into the place to open (S2). Driven through the
// MensajeriaPush seam, so no Firebase platform channel is touched. Demo S2:
// a message received with the app in the foreground is handed to the app.
import 'dart:async';

import 'package:crowdradar/core/push/receptor_push.dart';
import 'package:crowdradar/core/push/receptor_push_fcm.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _MensajeriaFalsa mensajeria;
  late ReceptorPush receptor;

  setUp(() {
    mensajeria = _MensajeriaFalsa();
    receptor = ReceptorPushFcm(mensajeria: mensajeria);
  });

  tearDown(() => mensajeria.cerrar());

  Future<List<int>> lugaresTrasInicializar() async {
    final lugares = <int>[];
    final sub = receptor.lugarAbierto.listen(lugares.add);
    addTearDown(sub.cancel);
    await receptor.inicializar();
    return lugares;
  }

  test('building the receiver touches no messaging operation', () {
    ReceptorPushFcm(mensajeria: mensajeria);

    expect(mensajeria.llamadas, isEmpty);
  });

  test('inicializar starts Firebase first, then asks permission', () async {
    await receptor.inicializar();

    expect(mensajeria.llamadas.first, 'iniciarFirebase');
    expect(mensajeria.llamadas, contains('pedirPermiso'));
  });

  test('inicializar twice starts Firebase and listens only once', () async {
    await receptor.inicializar();
    await receptor.inicializar();

    expect(
      mensajeria.llamadas.where((l) => l == 'iniciarFirebase'),
      hasLength(1),
    );
    expect(mensajeria.oyentesToques, 1);
  });

  test('S2 a tap with the app in background opens its lugarId', () async {
    final lugares = await lugaresTrasInicializar();

    mensajeria.tocar({'lugarId': '42'});
    await pumpEventQueue();

    expect(lugares, [42]);
  });

  test('S2 the tap that launched a terminated app opens its lugarId', () async {
    mensajeria.mensajeInicialData = {'lugarId': '7', 'nivel': 'ALTO'};

    final lugares = await lugaresTrasInicializar();
    await pumpEventQueue();

    expect(lugares, [7]);
  });

  test('S2 a missing or non-numeric lugarId is ignored', () async {
    mensajeria.mensajeInicialData = {'titulo': 'sin lugar'};
    final lugares = await lugaresTrasInicializar();

    mensajeria
      ..tocar({})
      ..tocar({'lugarId': 'abc'})
      ..tocar({'lugarId': ''})
      ..tocar({'lugarId': '5'});
    await pumpEventQueue();

    expect(lugares, [5]);
  });

  Future<List<MensajePrimerPlano>> mensajesTrasInicializar() async {
    final mensajes = <MensajePrimerPlano>[];
    final sub = receptor.mensajesEnPrimerPlano.listen(mensajes.add);
    addTearDown(sub.cancel);
    await receptor.inicializar();
    return mensajes;
  }

  test(
    'demo S2 a foreground message carries its title, body and lugarId',
    () async {
      final mensajes = await mensajesTrasInicializar();

      mensajeria.recibir(
        titulo: 'Alerta de saturación',
        cuerpo: 'Parque Kennedy ahora está Saturado.',
        data: {'lugarId': '42', 'nivel': 'SATURADO'},
      );
      await pumpEventQueue();

      expect(mensajes, hasLength(1));
      expect(mensajes.single.titulo, 'Alerta de saturación');
      expect(mensajes.single.cuerpo, 'Parque Kennedy ahora está Saturado.');
      expect(mensajes.single.lugarId, 42);
    },
  );

  test('demo S2 a foreground message without a numeric lugarId still arrives, '
      'with no place to open', () async {
    final mensajes = await mensajesTrasInicializar();

    mensajeria
      ..recibir(titulo: 'Sin lugar', data: {})
      ..recibir(cuerpo: 'Id roto', data: {'lugarId': 'abc'});
    await pumpEventQueue();

    expect(mensajes.map((m) => m.lugarId), [null, null]);
    expect(mensajes.map((m) => m.titulo), ['Sin lugar', null]);
    expect(mensajes.map((m) => m.cuerpo), [null, 'Id roto']);
  });

  test('demo S2 a foreground message is not a tap: no place opens', () async {
    final lugares = await lugaresTrasInicializar();

    mensajeria.recibir(titulo: 'Alerta', data: {'lugarId': '42'});
    await pumpEventQueue();

    expect(lugares, isEmpty);
  });

  test(
    'demo S2 inicializar twice listens to foreground messages once',
    () async {
      await receptor.inicializar();
      await receptor.inicializar();

      expect(mensajeria.oyentesMensajes, 1);
    },
  );

  test('inicializar rethrows a Firebase start failure and retries', () async {
    mensajeria.errorIniciar = StateError('sin google-services');

    await expectLater(receptor.inicializar(), throwsStateError);
    expect(mensajeria.oyentesToques, 0);
    expect(mensajeria.oyentesMensajes, 0);

    mensajeria.errorIniciar = null;
    await receptor.inicializar();
    expect(mensajeria.oyentesToques, 1);
    expect(mensajeria.oyentesMensajes, 1);
  });

  test('S1 obtenerToken returns the FCM token', () async {
    mensajeria.token = 'token-fcm';

    expect(await receptor.obtenerToken(), 'token-fcm');
  });

  test('S1 obtenerToken never asks before Firebase is started', () async {
    final iniciar = Completer<void>();
    mensajeria
      ..token = 'token-fcm'
      ..iniciarFirebaseCon = iniciar.future;

    final token = receptor.obtenerToken();
    await pumpEventQueue();
    expect(mensajeria.llamadas, ['iniciarFirebase']);

    iniciar.complete();
    expect(await token, 'token-fcm');
    expect(mensajeria.llamadas, ['iniciarFirebase', 'obtenerToken']);
  });

  test('S1 a token error yields null (iOS without APNs)', () async {
    mensajeria.errorToken = StateError('apns-token-not-set');

    expect(await receptor.obtenerToken(), isNull);
  });

  test('S1 a Firebase start failure yields no token and is retried', () async {
    mensajeria.errorIniciar = StateError('sin google-services');

    expect(await receptor.obtenerToken(), isNull);

    mensajeria
      ..errorIniciar = null
      ..token = 'token-fcm';
    expect(await receptor.obtenerToken(), 'token-fcm');
  });
}

/// Records which messaging operations ran and lets a test drive taps,
/// foreground messages, the launch message and the token.
class _MensajeriaFalsa implements MensajeriaPush {
  final llamadas = <String>[];
  final _toques = StreamController<Map<String, dynamic>>.broadcast();
  final _mensajes = StreamController<MensajeFcm>.broadcast();
  int oyentesToques = 0;
  int oyentesMensajes = 0;

  Map<String, dynamic>? mensajeInicialData;
  String? token;
  Object? errorToken;
  Object? errorIniciar;
  Future<void>? iniciarFirebaseCon;

  void tocar(Map<String, dynamic> data) => _toques.add(data);

  /// A message received while the app is in the foreground.
  void recibir({
    String? titulo,
    String? cuerpo,
    Map<String, dynamic> data = const {},
  }) => _mensajes.add((titulo: titulo, cuerpo: cuerpo, data: data));

  Future<void> cerrar() async {
    await _toques.close();
    await _mensajes.close();
  }

  @override
  Future<void> iniciarFirebase() async {
    llamadas.add('iniciarFirebase');
    await iniciarFirebaseCon;
    final error = errorIniciar;
    if (error != null) throw error;
  }

  @override
  Future<void> pedirPermiso() async => llamadas.add('pedirPermiso');

  @override
  Future<String?> obtenerToken() async {
    llamadas.add('obtenerToken');
    final error = errorToken;
    if (error != null) throw error;
    return token;
  }

  @override
  Stream<Map<String, dynamic>> get toques {
    oyentesToques++;
    llamadas.add('toques');
    return _toques.stream;
  }

  @override
  Stream<MensajeFcm> get mensajesEnPrimerPlano {
    oyentesMensajes++;
    llamadas.add('mensajesEnPrimerPlano');
    return _mensajes.stream;
  }

  @override
  Future<Map<String, dynamic>?> mensajeInicial() async {
    llamadas.add('mensajeInicial');
    return mensajeInicialData;
  }
}
