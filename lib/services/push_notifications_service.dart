/// Estrutura preparada para notificações push — SEM integração real ainda.
///
/// Para ativar de verdade, falta:
/// 1. Criar um projeto Firebase e baixar `google-services.json` para
///    `android/app/`.
/// 2. Adicionar `firebase_core` e `firebase_messaging` ao `pubspec.yaml`.
/// 3. Implementar `init()`/`requestPermission()`/`registerToken()` de fato
///    usando `FirebaseMessaging.instance`.
/// 4. Criar `POST /api/atleta/push-token` no backend Next.js (puro-chao-gestao)
///    para associar o token do device ao atleta autenticado, e disparar
///    notificações a partir de eventos existentes (ex.: mensalidade vencendo,
///    aviso publicado) em vez de/complementando o WhatsApp atual.
///
/// Instanciado e chamado em `main()` desde já como no-op, para não exigir
/// reestruturar o app quando o push for implementado de verdade.
class PushNotificationsService {
  Future<void> init() async {
    // TODO(push): inicializar Firebase Messaging aqui.
  }

  Future<bool> requestPermission() async {
    // TODO(push): solicitar permissão de notificação ao usuário.
    return false;
  }

  Future<void> registerToken() async {
    // TODO(push): obter o token FCM e enviar para
    // POST /api/atleta/push-token.
  }
}
