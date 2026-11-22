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

  bool get hasUpdate => compareVersions(latestVersion, currentVersion) > 0;

  @visibleForTesting
  static int compareVersions(String v1, String v2) {
    final parsed1 = _parseVersion(v1);
    final parsed2 = _parseVersion(v2);

    for (int i = 0; i < 3; i++) {
      final cmp = parsed1.core[i].compareTo(parsed2.core[i]);
      if (cmp != 0) return cmp;
    }

    final preCmp = _comparePreRelease(parsed1.preRelease, parsed2.preRelease);
    if (preCmp != 0) return preCmp;

    // Only compare +build metadata when both versions explicitly specify it,
    // because GitHub release tags (vX.Y.Z) omit +build while local builds may
    // carry pubspec build numbers.
    if (parsed1.build != null && parsed2.build != null) {
      return _compareIdentifiers(parsed1.build!, parsed2.build!);
    }
    return 0;
  }

  static ({List<int> core, List<String>? preRelease, List<String>? build})
  _parseVersion(String raw) {
    var normalized = raw.trim();
    if (normalized.startsWith('v') || normalized.startsWith('V')) {
      normalized = normalized.substring(1);
    }

    final plusIndex = normalized.indexOf('+');
    List<String>? build;
    if (plusIndex != -1) {
      final buildStr = normalized.substring(plusIndex + 1);
      if (buildStr.isNotEmpty) {
        build = buildStr.split('.');
      }
      normalized = normalized.substring(0, plusIndex);
    }

    final dashIndex = normalized.indexOf('-');
    List<String>? preRelease;
    if (dashIndex != -1) {
      final preStr = normalized.substring(dashIndex + 1);
      if (preStr.isNotEmpty) {
        preRelease = preStr.split('.');
      }
      normalized = normalized.substring(0, dashIndex);
    }

    final rawParts = normalized.split('.');
    final core = List<int>.generate(
      3,
      (i) => i < rawParts.length ? (int.tryParse(rawParts[i]) ?? 0) : 0,
    );
    return (core: core, preRelease: preRelease, build: build);
  }

  static int _comparePreRelease(List<String>? pre1, List<String>? pre2) {
    if (pre1 == null && pre2 == null) return 0;
    // A normal version has higher precedence than a pre-release version.
    if (pre1 == null) return 1;
    if (pre2 == null) return -1;
    return _compareIdentifiers(pre1, pre2);
  }

  static int _compareIdentifiers(List<String> ids1, List<String> ids2) {
    final len = ids1.length < ids2.length ? ids1.length : ids2.length;
    for (int i = 0; i < len; i++) {
      final a = ids1[i];
      final b = ids2[i];
      final aNum = int.tryParse(a);
      final bNum = int.tryParse(b);
      if (aNum != null && bNum != null) {
        final cmp = aNum.compareTo(bNum);
        if (cmp != 0) return cmp;
      } else if (aNum != null) {
        // SemVer 2.0: numeric identifiers always have lower precedence.
        return -1;
      } else if (bNum != null) {
        return 1;
      } else {
        final cmp = a.compareTo(b);
        if (cmp != 0) return cmp;
      }
    }
    return ids1.length.compareTo(ids2.length);
  }
}

class UpdateService {
  static bool hasCheckedOnStartup = false;

  final Dio _dio;

  UpdateService({Dio? dio})
    : _dio =
          dio ??
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
      final response = await _dio.get<Map<String, dynamic>>(
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
    result = result.replaceAllMapped(
      RegExp(r'\*\*(.+?)\*\*'),
      (m) => m.group(1)!,
    );
    result = result.replaceAllMapped(RegExp(r'__(.+?)__'), (m) => m.group(1)!);

    // Remove italic (*texto* ou _texto_)
    result = result.replaceAllMapped(RegExp(r'\*(.+?)\*'), (m) => m.group(1)!);
    result = result.replaceAllMapped(RegExp(r'_(.+?)_'), (m) => m.group(1)!);

    // Remove horizontal rules
    result = result.replaceAll(
      RegExp(r'^[\-\*_]{3,}\s*$', multiLine: true),
      '',
    );

    // Remove links [texto](url) -> texto
    result = result.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\([^\)]+\)'),
      (m) => m.group(1)!,
    );

    // Remove inline code `código`
    result = result.replaceAllMapped(RegExp(r'`([^`]+)`'), (m) => m.group(1)!);

    // Remove code blocks
    result = result.replaceAll(RegExp(r'```[\s\S]*?```'), '');

    // Remove múltiplas linhas em branco
    result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return result.trim();
  }
}
