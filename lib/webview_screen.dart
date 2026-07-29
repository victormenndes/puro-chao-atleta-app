import 'dart:async';

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
  final path = uri.path;
  return kAllowedPathPrefixes.any((p) => path == p || path.startsWith('$p/'));
}

const Set<String> kAllowedExternalSchemes = {'https', 'tel', 'mailto', 'whatsapp'};

bool isExternalSchemeAllowed(Uri uri) => kAllowedExternalSchemes.contains(uri.scheme.toLowerCase());

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _hasError = false;
  bool _isLoading = true;
  bool _isSlowLoading = false;
  Timer? _slowLoadingTimer;

  bool _isInScope(Uri uri) => isAtletaAppUrlInScope(uri);

  Future<void> _openExternally(Uri uri) async {
    if (!isExternalSchemeAllowed(uri)) {
      _showSnack('Link não suportado');
      return;
    }
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
            _slowLoadingTimer?.cancel();
            _slowLoadingTimer = Timer(const Duration(seconds: 6), () {
              if (mounted) setState(() => _isSlowLoading = true);
            });
            setState(() {
              _isLoading = true;
              _isSlowLoading = false;
              _hasError = false;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            _slowLoadingTimer?.cancel();
            setState(() {
              _isLoading = false;
              _isSlowLoading = false;
            });
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

  void _showSnack(String message, {SnackBarAction? action, Duration duration = const Duration(seconds: 3)}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF14151D),
        behavior: SnackBarBehavior.floating,
        duration: duration,
        content: Text(
          message,
          style: const TextStyle(color: Color(0xFFF3EFE7), fontWeight: FontWeight.w600),
        ),
        action: action,
      ),
    );
  }

  void _showUpdateBanner(String apkUrl) {
    _showSnack(
      'Nova versão disponível',
      duration: const Duration(seconds: 10),
      action: SnackBarAction(
        label: 'Baixar',
        textColor: const Color(0xFF5A82FF),
        onPressed: () => _openExternally(Uri.parse(apkUrl)),
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

  DateTime? _lastBackPressAt;

  Future<bool> _handleBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    final now = DateTime.now();
    if (_lastBackPressAt != null && now.difference(_lastBackPressAt!) < const Duration(seconds: 2)) {
      return true;
    }
    _lastBackPressAt = now;
    _showSnack('Toque novamente para sair', duration: const Duration(seconds: 2));
    return false;
  }

  @override
  void dispose() {
    _slowLoadingTimer?.cancel();
    super.dispose();
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
                    if (_isLoading) _BrandLoadingIndicator(showSlowMessage: _isSlowLoading),
                  ],
                ),
        ),
      ),
    );
  }
}

class _BrandLoadingIndicator extends StatefulWidget {
  const _BrandLoadingIndicator({required this.showSlowMessage});

  final bool showSlowMessage;

  @override
  State<_BrandLoadingIndicator> createState() => _BrandLoadingIndicatorState();
}

class _BrandLoadingIndicatorState extends State<_BrandLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);
  late final Animation<double> _opacity = Tween<double>(begin: 0.55, end: 1.0)
      .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _opacity,
            child: Image.asset('assets/splash/splash_logo.png', width: 88, height: 88),
          ),
          const SizedBox(height: 18),
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: Color(0xFF5A82FF)),
          ),
          if (widget.showSlowMessage) ...[
            const SizedBox(height: 16),
            const Text(
              'Conexão lenta, aguarde um instante...',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0x8FF3EFE7), fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}
