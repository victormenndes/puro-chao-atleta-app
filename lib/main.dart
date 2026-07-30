import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'webview_screen.dart';
import 'services/push_notifications_service.dart';

// Isolate separado do main() — precisa inicializar o Firebase de novo aqui
// dentro. FCM já exibe a notificação sozinho neste estado (mensagem sempre
// tem bloco notification+data — ver sendAthletePush no backend); este
// handler só existe pra satisfazer o plugin, sem side-effects.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await PushNotificationsService.instance.initLocalNotifications();
  runApp(const AtletaApp());
}

class AtletaApp extends StatelessWidget {
  const AtletaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Puro Chão — Atleta',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F13),
      ),
      home: const WebViewScreen(),
    );
  }
}
