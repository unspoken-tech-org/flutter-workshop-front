import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/env_config.dart';

class UpdateInfo {
  final String latestVersion;
  final String currentVersion;
  final String downloadUrl;
  final String releaseNotes;
  final DateTime publishedAt;

  UpdateInfo({
    required this.latestVersion,
    required this.currentVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.publishedAt,
  });

  bool get hasUpdate => _compareVersions(latestVersion, currentVersion) > 0;

  static int _compareVersions(String v1, String v2) {
    // Remove suffixes like -test, -beta, +build
    final cleanV1 = v1.split(RegExp(r'[-+]'))[0];
    final cleanV2 = v2.split(RegExp(r'[-+]'))[0];

    final parts1 = cleanV1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = cleanV2.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (int i = 0; i < 3; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    return 0;
  }
}

class UpdateService {
  static bool hasCheckedOnStartup = false;

  final Dio _dio;

  UpdateService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                headers: const {'Accept': 'application/vnd.github.v3+json'},
              ),
            );

  Future<UpdateInfo?> checkForUpdates() async {
    final owner = EnvConfig.githubOwner;
    final repo = EnvConfig.githubRepo;

    if (owner.isEmpty || repo.isEmpty) {
      return null;
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    try {
      final response = await _dio.get(
        'https://api.github.com/repos/$owner/$repo/releases/latest',
      );

      if (response.statusCode != 200) return null;

      final data = response.data as Map<String, dynamic>;
      final latestVersion = (data['tag_name'] as String).replaceFirst('v', '');
      final rawNotes = (data['body'] as String?) ?? 'Sem notas de atualização';
      final publishedAt = DateTime.parse(data['published_at'] as String);

      String? downloadUrl;
      final assets = data['assets'] as List<dynamic>?;
      if (assets != null) {
        for (final asset in assets) {
          final a = asset as Map<String, dynamic>;
          final name = (a['name'] as String).toLowerCase();
          if (name.endsWith('.exe')) {
            downloadUrl = a['browser_download_url'] as String;
            break;
          }
        }
      }
      downloadUrl ??= data['html_url'] as String;

      return UpdateInfo(
        latestVersion: latestVersion,
        currentVersion: currentVersion,
        downloadUrl: downloadUrl,
        releaseNotes: _stripMarkdown(rawNotes),
        publishedAt: publishedAt,
      );
    } catch (e) {
      debugPrint('Erro ao verificar atualizações: $e');
      return null;
    }
  }

  Future<void> openDownloadUrl(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      throw Exception('Não foi possível abrir o link de download');
    }
  }

  String _stripMarkdown(String markdown) {
    var result = markdown;

    // Remove headers (# ## ###)
    result = result.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');

    // Remove bold (**texto** ou __texto__)
    result =
        result.replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => m.group(1)!);
    result = result.replaceAllMapped(RegExp(r'__(.+?)__'), (m) => m.group(1)!);

    // Remove italic (*texto* ou _texto_)
    result = result.replaceAllMapped(RegExp(r'\*(.+?)\*'), (m) => m.group(1)!);
    result = result.replaceAllMapped(RegExp(r'_(.+?)_'), (m) => m.group(1)!);

    // Remove horizontal rules
    result =
        result.replaceAll(RegExp(r'^[\-\*_]{3,}\s*$', multiLine: true), '');

    // Remove links [texto](url) -> texto
    result = result.replaceAllMapped(
        RegExp(r'\[([^\]]+)\]\([^\)]+\)'), (m) => m.group(1)!);

    // Remove inline code `código`
    result = result.replaceAllMapped(RegExp(r'`([^`]+)`'), (m) => m.group(1)!);

    // Remove code blocks
    result = result.replaceAll(RegExp(r'```[\s\S]*?```'), '');

    // Remove múltiplas linhas em branco
    result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return result.trim();
  }
}
