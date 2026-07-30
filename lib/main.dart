import 'package:flutter/material.dart';
import 'webview_screen.dart';
import 'services/push_notifications_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AtletaApp());
  // Fire-and-forget: push é um extra, nunca pode atrasar ou travar a
  // primeira tela do app. Qualquer falha (Play Services ausente/antigo,
  // config do Firebase, etc.) é tratada dentro do próprio serviço.
  PushNotificationsService.instance.initialize();
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
