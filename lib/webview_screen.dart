import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'no_connection_screen.dart';
import 'services/update_checker.dart';
import 'services/push_notifications_service.dart';

const String kHost = 'purochao.mendestechnology.com.br';
// Painel, não login: a sessão do atleta é um cookie HttpOnly de 7 dias
// (purochao-atleta) já validado pelo backend em GET /api/atleta/me. O
// próprio painel redireciona para /atleta/login se o cookie estiver
// ausente, expirado ou revogado — abrir direto no login aqui ignorava
// esse cookie e forçava um novo OTP toda vez que o app era reaberto.
const String kStartUrl = 'https://$kHost/atleta/painel';
const List<String> kAllowedPathPrefixes = ['/atleta', '/api/atleta'];

bool isAtletaAppUrlInScope(Uri uri) {
  if (uri.host != kHost) return false;
  return kAllowedPathPrefixes.any((p) => uri.path.startsWith(p));
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _hasError = false;
  bool _isLoading = true;

  bool _isInScope(Uri uri) => isAtletaAppUrlInScope(uri);

  Future<void> _openExternally(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void initState() {
    super.initState();

    // Estrutura preparada para push (sem efeito real ainda, ver TODOs no service).
    PushNotificationsService().init();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // Marcador no User-Agent para o site (pwa-register.tsx) detectar que
      // está rodando dentro do app nativo e não mostrar o banner de "instalar
      // o app" (redundante e que sobrepõe conteúdo dentro do próprio app).
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/125.0.0.0 Mobile Safari/537.36 '
        'PuroChaoAtletaApp/1.0',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            if (error.isForMainFrame ?? true) {
              setState(() => _hasError = true);
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            final uri = Uri.parse(request.url);
            if (_isInScope(uri)) {
              return NavigationDecision.navigate;
            }
            _openExternally(uri);
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(kStartUrl));

    _checkForUpdateSoon();
  }

  void _checkForUpdateSoon() {
    Future.delayed(const Duration(seconds: 2), () async {
      final update = await checkForUpdate();
      if (update != null && mounted) {
        _showUpdateBanner(update.apkUrl);
      }
    });
  }

  void _showUpdateBanner(String apkUrl) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF14151D),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 10),
        content: const Text(
          'Nova versão disponível',
          style: TextStyle(color: Color(0xFFF3EFE7), fontWeight: FontWeight.w600),
        ),
        action: SnackBarAction(
          label: 'Baixar',
          textColor: const Color(0xFF5A82FF),
          onPressed: () => _openExternally(Uri.parse(apkUrl)),
        ),
      ),
    );
  }

  Future<void> _retry() async {
    setState(() => _hasError = false);
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      setState(() => _hasError = true);
      return;
    }
    await _controller.reload();
  }

  Future<bool> _handleBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _handleBack();
        if (shouldPop) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F13),
        body: SafeArea(
          child: _hasError
              ? NoConnectionScreen(onRetry: _retry)
              : Stack(
                  children: [
                    WebViewWidget(controller: _controller),
                    if (_isLoading)
                      const Center(
                        child: CircularProgressIndicator(color: Color(0xFF5A82FF)),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
