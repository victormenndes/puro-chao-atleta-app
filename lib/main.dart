import 'package:flutter/material.dart';
import 'webview_screen.dart';

void main() => runApp(const AtletaApp());

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
