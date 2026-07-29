import 'package:flutter_test/flutter_test.dart';
import 'package:atleta/webview_screen.dart';

void main() {
  test('kStartUrl aponta pro painel, não pro login', () {
    expect(kStartUrl, 'https://$kHost/atleta/painel');
  });

  group('isAtletaAppUrlInScope', () {
    test('aceita painel do atleta', () {
      expect(isAtletaAppUrlInScope(Uri.parse('https://$kHost/atleta/painel')), isTrue);
    });

    test('aceita login do atleta', () {
      expect(isAtletaAppUrlInScope(Uri.parse('https://$kHost/atleta/login')), isTrue);
    });

    test('aceita rotas de API do atleta', () {
      expect(isAtletaAppUrlInScope(Uri.parse('https://$kHost/api/atleta/me')), isTrue);
    });

    test('rejeita host diferente', () {
      expect(isAtletaAppUrlInScope(Uri.parse('https://evil.com/atleta/painel')), isFalse);
    });

    test('rejeita caminho fora do escopo', () {
      expect(isAtletaAppUrlInScope(Uri.parse('https://$kHost/admin')), isFalse);
    });

    test('aceita /atleta sozinho (sem sufixo, landing exato)', () {
      expect(isAtletaAppUrlInScope(Uri.parse('https://$kHost/atleta')), isTrue);
    });

    test('rejeita /atleta-falso (prefixo textual, não de path)', () {
      expect(isAtletaAppUrlInScope(Uri.parse('https://$kHost/atleta-falso')), isFalse);
    });

    test('rejeita /atletaqualquercoisa', () {
      expect(isAtletaAppUrlInScope(Uri.parse('https://$kHost/atletaqualquercoisa')), isFalse);
    });

    test('rejeita /api/atleta-hack', () {
      expect(isAtletaAppUrlInScope(Uri.parse('https://$kHost/api/atleta-hack')), isFalse);
    });
  });

  group('isExternalSchemeAllowed', () {
    test('permite https', () {
      expect(isExternalSchemeAllowed(Uri.parse('https://exemplo.com')), isTrue);
    });

    test('permite tel', () {
      expect(isExternalSchemeAllowed(Uri.parse('tel:+5511999999999')), isTrue);
    });

    test('permite mailto', () {
      expect(isExternalSchemeAllowed(Uri.parse('mailto:contato@purochao.com')), isTrue);
    });

    test('permite whatsapp', () {
      expect(isExternalSchemeAllowed(Uri.parse('whatsapp://send?phone=5511999999999')), isTrue);
    });

    test('rejeita http (produção só usa https)', () {
      expect(isExternalSchemeAllowed(Uri.parse('http://exemplo.com')), isFalse);
    });

    test('rejeita esquemas desconhecidos/potencialmente perigosos', () {
      expect(isExternalSchemeAllowed(Uri.parse('intent://foo#Intent;end')), isFalse);
      expect(isExternalSchemeAllowed(Uri.parse('market://details?id=x')), isFalse);
      expect(isExternalSchemeAllowed(Uri.parse('javascript:alert(1)')), isFalse);
    });
  });
}
