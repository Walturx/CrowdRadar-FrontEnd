import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../firebase_options.dart';
import 'receptor_push.dart';

/// Adapter pattern: [ReceptorPush] backed by Firebase Cloud Messaging.
///
/// Android shows a notification sent while the app is in background or
/// terminated; tapping it opens the place in its `data.lugarId`. Foreground
/// messages are not shown (the in-app inbox covers them). iOS has no APNs key,
/// so it gets no token and no push, but never crashes.
///
/// Building it touches nothing; only [inicializar] and [obtenerToken] start
/// Firebase, so a token is never requested before Firebase is ready.
class ReceptorPushFcm implements ReceptorPush {
  final MensajeriaPush _mensajeria;
  final _lugares = StreamController<int>.broadcast();

  /// Firebase start in flight or done; cleared on failure so it is retried.
  Future<void>? _firebase;
  Future<void>? _inicializacion;

  ReceptorPushFcm({MensajeriaPush? mensajeria})
    : _mensajeria = mensajeria ?? MensajeriaFirebase();

  @override
  Stream<int> get lugarAbierto => _lugares.stream;

  /// Starts Firebase, listens to taps (background and launch) and asks the
  /// notification permission (Android 13+). Runs once.
  @override
  Future<void> inicializar() => _inicializacion ??= _inicializar();

  Future<void> _inicializar() async {
    try {
      await _iniciarFirebase();
    } catch (_) {
      _inicializacion = null; // Retried on the next call.
      rethrow;
    }
    _mensajeria.toques.listen(_alTocar);
    // The tap that launched the app is handled before the permission dialog,
    // so the place opens without waiting for the user's answer.
    final inicial = await _mensajeria.mensajeInicial();
    if (inicial != null) _alTocar(inicial);
    await _mensajeria.pedirPermiso();
  }

  /// The FCM token, or null when unavailable (Firebase did not start, no
  /// network, or iOS without an APNs key).
  @override
  Future<String?> obtenerToken() async {
    try {
      await _iniciarFirebase();
      return await _mensajeria.obtenerToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> _iniciarFirebase() async {
    final enCurso = _firebase ??= _mensajeria.iniciarFirebase();
    try {
      await enCurso;
    } catch (_) {
      if (identical(_firebase, enCurso)) _firebase = null;
      rethrow;
    }
  }

  void _alTocar(Map<String, dynamic> data) {
    final lugarId = int.tryParse('${data['lugarId'] ?? ''}');
    if (lugarId != null) _lugares.add(lugarId);
  }
}

/// The Firebase Messaging operations [ReceptorPushFcm] needs: the seam that
/// keeps it testable without Firebase platform channels.
abstract class MensajeriaPush {
  /// Starts Firebase; a second call when it is already started does nothing.
  Future<void> iniciarFirebase();

  Future<void> pedirPermiso();

  Future<String?> obtenerToken();

  /// `data` of each notification tapped while the app was in background.
  Stream<Map<String, dynamic>> get toques;

  /// `data` of the notification that launched the app, if any.
  Future<Map<String, dynamic>?> mensajeInicial();
}

/// [MensajeriaPush] on the real Firebase SDK. Reads `FirebaseMessaging`
/// lazily: it fails until Firebase is started.
class MensajeriaFirebase implements MensajeriaPush {
  FirebaseMessaging get _fcm => FirebaseMessaging.instance;

  @override
  Future<void> iniciarFirebase() async {
    if (Firebase.apps.isNotEmpty) return;
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  @override
  Future<void> pedirPermiso() => _fcm.requestPermission();

  /// The FCM registration token the backend sends to with firebase-admin
  /// `sendEachForMulticast`. firebase_messaging 17 deprecates it for FID
  /// direct-send (`register`/`onRegistered`), a different target the backend
  /// does not use.
  @override
  // ignore: deprecated_member_use
  Future<String?> obtenerToken() => _fcm.getToken();

  @override
  Stream<Map<String, dynamic>> get toques =>
      FirebaseMessaging.onMessageOpenedApp.map((m) => m.data);

  @override
  Future<Map<String, dynamic>?> mensajeInicial() async =>
      (await _fcm.getInitialMessage())?.data;
}
