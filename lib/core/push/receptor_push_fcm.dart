import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Color;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';
import 'receptor_push.dart';

/// Adapter pattern: [ReceptorPush] backed by Firebase Cloud Messaging.
///
/// Android shows a notification sent while the app is in background or
/// terminated; tapping it opens the place in its `data.lugarId`. A message
/// received in the foreground gets no system notification: it is handed to
/// the app through [mensajesEnPrimerPlano] and posted to the tray through
/// [MensajeriaPush.mostrarEnBandeja]. iOS has no APNs key, so it gets no
/// token and no push, but never crashes.
///
/// Building it touches nothing; only [inicializar] and [obtenerToken] start
/// Firebase, so a token is never requested before Firebase is ready.
class ReceptorPushFcm implements ReceptorPush {
  final MensajeriaPush _mensajeria;
  final _lugares = StreamController<int>.broadcast();
  final _mensajes = StreamController<MensajePrimerPlano>.broadcast();

  /// Firebase start in flight or done; cleared on failure so it is retried.
  Future<void>? _firebase;
  Future<void>? _inicializacion;

  ReceptorPushFcm({MensajeriaPush? mensajeria})
    : _mensajeria = mensajeria ?? MensajeriaFirebase();

  @override
  Stream<int> get lugarAbierto => _lugares.stream;

  @override
  Stream<MensajePrimerPlano> get mensajesEnPrimerPlano => _mensajes.stream;

  /// Starts Firebase, listens to taps (background and launch) and to
  /// foreground messages, and asks the notification permission (Android 13+).
  /// Runs once.
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
    _mensajeria.mensajesEnPrimerPlano.listen(_alRecibir);
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
    final lugarId = _lugarDe(data);
    if (lugarId != null) _lugares.add(lugarId);
  }

  /// Every foreground message is handed over, even without a valid place: the
  /// notice still shows its texts, just with nothing to open. It is also
  /// posted to the notification tray so it stays there after the notice goes;
  /// a tray failure (permission denied) never blocks the notice.
  void _alRecibir(MensajeFcm m) {
    _mensajes.add(
      MensajePrimerPlano(
        titulo: m.titulo,
        cuerpo: m.cuerpo,
        lugarId: _lugarDe(m.data),
      ),
    );
    _mensajeria.mostrarEnBandeja(m).catchError((Object _) {});
  }

  static int? _lugarDe(Map<String, dynamic> data) =>
      int.tryParse('${data['lugarId'] ?? ''}');
}

/// The Firebase Messaging operations [ReceptorPushFcm] needs: the seam that
/// keeps it testable without Firebase platform channels.
abstract class MensajeriaPush {
  /// Starts Firebase; a second call when it is already started does nothing.
  Future<void> iniciarFirebase();

  Future<void> pedirPermiso();

  Future<String?> obtenerToken();

  /// `data` of each notification tapped while the app was running: an FCM
  /// notification shown in background, or one posted by [mostrarEnBandeja].
  Stream<Map<String, dynamic>> get toques;

  /// `data` of the notification that launched the app, if any.
  Future<Map<String, dynamic>?> mensajeInicial();

  /// Each message received while the app is in the foreground.
  Stream<MensajeFcm> get mensajesEnPrimerPlano;

  /// Posts a foreground message to the system notification tray, where
  /// Android puts nothing by itself while the app is open.
  Future<void> mostrarEnBandeja(MensajeFcm mensaje);
}

/// The parts of an FCM message the app reads: the notification texts and the
/// `data` payload.
typedef MensajeFcm = ({
  String? titulo,
  String? cuerpo,
  Map<String, dynamic> data,
});

/// [MensajeriaPush] on the real Firebase SDK. Reads `FirebaseMessaging`
/// lazily: it fails until Firebase is started.
class MensajeriaFirebase implements MensajeriaPush {
  /// Android channel of the tray notifications; FCM background notifications
  /// keep the SDK's default channel.
  static const _canal = AndroidNotificationChannel(
    'alertas_favoritos',
    'Alertas de favoritos',
    description: 'Cambios de saturación en tus lugares favoritos',
    importance: Importance.high,
  );

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  final _locales = FlutterLocalNotificationsPlugin();
  final _toquesLocales = StreamController<Map<String, dynamic>>.broadcast();
  Future<void>? _localesListas;
  int _siguienteId = 0;

  /// Starts the local notifications plugin and its channel once; taps on its
  /// notifications carry the message `data` as a JSON payload.
  Future<void> _iniciarLocales() => _localesListas ??= () async {
    await _locales.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notification'),
      ),
      onDidReceiveNotificationResponse: (r) {
        final data = _dataDe(r.payload);
        if (data != null) _toquesLocales.add(data);
      },
    );
    await _locales
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_canal);
  }();

  static Map<String, dynamic>? _dataDe(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final data = jsonDecode(payload);
      return data is Map<String, dynamic> ? data : null;
    } catch (_) {
      return null;
    }
  }

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
  Stream<Map<String, dynamic>> get toques {
    final fcm = FirebaseMessaging.onMessageOpenedApp.map((m) => m.data);
    final salida = StreamController<Map<String, dynamic>>.broadcast();
    fcm.listen(salida.add);
    _toquesLocales.stream.listen(salida.add);
    return salida.stream;
  }

  /// The FCM notification that launched the app or, failing that, a tray
  /// notification posted by [mostrarEnBandeja] that did.
  @override
  Future<Map<String, dynamic>?> mensajeInicial() async {
    final fcm = (await _fcm.getInitialMessage())?.data;
    if (fcm != null) return fcm;
    await _iniciarLocales();
    final detalles = await _locales.getNotificationAppLaunchDetails();
    if (detalles?.didNotificationLaunchApp != true) return null;
    return _dataDe(detalles?.notificationResponse?.payload);
  }

  @override
  Future<void> mostrarEnBandeja(MensajeFcm mensaje) async {
    await _iniciarLocales();
    await _locales.show(
      id: _siguienteId++,
      title: mensaje.titulo,
      body: mensaje.cuerpo,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _canal.id,
          _canal.name,
          channelDescription: _canal.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
          color: const Color(0xFF1A3C8F),
        ),
      ),
      payload: jsonEncode(mensaje.data),
    );
  }

  @override
  Stream<MensajeFcm> get mensajesEnPrimerPlano =>
      FirebaseMessaging.onMessage.map(
        (m) => (
          titulo: m.notification?.title,
          cuerpo: m.notification?.body,
          data: m.data,
        ),
      );
}
