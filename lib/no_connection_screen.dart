import 'package:flutter/material.dart';

/// Tela exibida quando o WebView não consegue carregar (sem rede ou erro do
/// servidor). Mantém o tema escuro do Puro Chão para não quebrar a
/// experiência visual do app.
class NoConnectionScreen extends StatelessWidget {
  const NoConnectionScreen({super.key, required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F0F13),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 56, color: Color(0xFF9AA1AB)),
          const SizedBox(height: 20),
          const Text(
            'Sem conexão',
            style: TextStyle(
              color: Color(0xFFF3EFE7),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Não foi possível carregar o Portal do Atleta. Verifique sua internet e tente novamente.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0x8FF3EFE7), fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1947E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Tentar novamente', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
