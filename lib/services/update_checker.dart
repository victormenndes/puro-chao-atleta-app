import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// Checagem best-effort de nova versão do app via JSON estático hospedado
/// junto do .apk em static.mendestechnology.com.br. Nunca bloqueia o uso do
/// app — falhas de rede ou parsing são silenciosas.
const String kVersionCheckUrl =
    'https://static.mendestechnology.com.br/apps/purochao-atleta-version.json';

class UpdateInfo {
  UpdateInfo({required this.apkUrl});
  final String apkUrl;
}

/// Retorna as infos de update se houver uma versão mais nova que a instalada,
/// ou `null` se já está atualizado ou a checagem falhou.
Future<UpdateInfo?> checkForUpdate() async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

    final response = await http
        .get(Uri.parse(kVersionCheckUrl))
        .timeout(const Duration(seconds: 6));
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final latestVersionCode = data['latestVersionCode'] as int?;
    final apkUrl = data['apkUrl'] as String?;
    if (latestVersionCode == null || apkUrl == null) return null;

    if (latestVersionCode > currentBuild) {
      return UpdateInfo(apkUrl: apkUrl);
    }
    return null;
  } catch (_) {
    return null;
  }
}
