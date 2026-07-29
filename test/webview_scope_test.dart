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
  });
}
