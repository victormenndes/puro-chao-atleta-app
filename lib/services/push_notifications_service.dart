import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kPushChannelId = 'purochao_important';
const String kPushChannelName = 'Avisos da Puro Chão';
const String _kAskedPrefKey = 'push_permission_asked_v1';

/// Singleton: inicializa FCM + notificações locais, mantém o token atual e
/// expõe callbacks pra WebViewScreen entregar o token à página (via ponte
/// JS) e navegar quando o usuário toca numa notificação.
class PushNotificationsService {
  PushNotificationsService._();
  static final PushNotificationsService instance = PushNotificationsService._();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  /// Chamado sempre que um token (inicial ou renovado) fica disponível.
  void Function(String token)? onTokenReady;

  /// Chamado quando o usuário toca numa notificação, com a rota já extraída
  /// do payload `{type, route}`.
  void Function(String route)? onNotificationTapped;

  String? _currentToken;
  bool _initialized = false;

  String? get currentToken => _currentToken;

  Future<void> initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotifications.initialize(
      settings: const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );

    const channel = AndroidNotificationChannel(
      kPushChannelId,
      kPushChannelName,
      description: 'Avisos e comunicados importantes da academia.',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _onLocalNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;
    _handleTapPayload(jsonDecode(payload) as Map<String, dynamic>);
  }

  void _handleTapPayload(Map<String, dynamic> data) {
    final route = data['route'] as String?;
    if (route != null && route.isNotEmpty) onNotificationTapped?.call(route);
  }

  /// Chamado quando a WebView atinge /atleta/painel (sinal de sessão
  /// válida). Registra os listeners uma única vez; se a permissão já
  /// tiver sido concedida antes, obtém e entrega o token sem novo diálogo.
  Future<void> onReachedPainel() async {
    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _handleTapPayload(m.data));
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      _currentToken = token;
      onTokenReady?.call(token);
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) _handleTapPayload(initialMessage.data);

    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _fetchAndDeliverToken();
    }
  }

  /// Só deve ser chamado a partir do diálogo explicativo mostrado pela UI,
  /// quando o usuário toca em "Ativar".
  Future<bool> requestPermissionAndRegister() async {
    final settings = await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
    final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    if (granted) await _fetchAndDeliverToken();
    return granted;
  }

  Future<void> _fetchAndDeliverToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    _currentToken = token;
    onTokenReady?.call(token);
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _localNotifications.show(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          kPushChannelId, kPushChannelName,
          channelDescription: 'Avisos e comunicados importantes da academia.',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// `false` se: já concedida (nada a fazer), recusada no diálogo NATIVO do
  /// Android (não dá pra pedir de novo por código — só em Configurações),
  /// ou já mostramos nosso diálogo explicativo antes e o usuário disse
  /// "agora não".
  Future<bool> shouldShowPermissionPrompt() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.denied) {
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_kAskedPrefKey) ?? false);
  }

  Future<void> markPermissionPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAskedPrefKey, true);
  }
}
