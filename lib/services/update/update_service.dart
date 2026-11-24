import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/env_config.dart';
import '../../core/logging/app_logger.dart';

enum UpdateInstallStage { downloading, verifying, launching }

class UpdateInstallException implements Exception {
  final String message;

  const UpdateInstallException(this.message);

  @override
  String toString() => message;
}

class ReleaseNoteEntry {
  final String version;
  final String notes;
  final DateTime publishedAt;

  const ReleaseNoteEntry({
    required this.version,
    required this.notes,
    required this.publishedAt,
  });
}

class UpdateInfo {
  final String latestVersion;
  final String currentVersion;
  final String downloadUrl;
  final String? checksumUrl;
  final String releaseNotes;
  final DateTime publishedAt;
  final List<ReleaseNoteEntry> releaseHistory;
  final bool hasTruncatedHistory;

  UpdateInfo({
    required this.latestVersion,
    required this.currentVersion,
    required this.downloadUrl,
    this.checksumUrl,
    required this.releaseNotes,
    required this.publishedAt,
    this.releaseHistory = const [],
    this.hasTruncatedHistory = false,
  });

  bool get hasUpdate => compareVersions(latestVersion, currentVersion) > 0;

  bool get supportsSilentInstall =>
      checksumUrl != null && checksumUrl!.isNotEmpty;

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

class _ParsedRelease {
  final String version;
  final String notes;
  final DateTime publishedAt;
  final String downloadUrl;
  final String? checksumUrl;

  const _ParsedRelease({
    required this.version,
    required this.notes,
    required this.publishedAt,
    required this.downloadUrl,
    this.checksumUrl,
  });
}

class UpdateService {
  static const String _logTag = 'Update';
  static bool hasCheckedOnStartup = false;
  static const int _maxPages = 3;
  static const String _emptyNotesFallback = 'Sem notas de atualização';

  final Dio _dio;
  final Future<void> Function(String exePath) _installerLauncher;
  final void Function() _onExit;
  final Directory? _tempDirectory;
  final bool _isWindows;
  final Future<PackageInfo> Function() _packageInfoLoader;
  final String? _feedUrlOverride;

  UpdateService({
    Dio? dio,
    Future<void> Function(String exePath)? installerLauncher,
    void Function()? onExit,
    Directory? tempDirectory,
    bool? isWindows,
    Future<PackageInfo> Function()? packageInfoLoader,
    String? feedUrlOverride,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 10),
               receiveTimeout: const Duration(seconds: 10),
               headers: const {'Accept': 'application/vnd.github.v3+json'},
             ),
           ),
       _installerLauncher = installerLauncher ?? _defaultInstallerLauncher,
       _onExit = onExit ?? (() => exit(0)),
       _tempDirectory = tempDirectory,
       _isWindows = isWindows ?? (!kIsWeb && Platform.isWindows),
       _packageInfoLoader = packageInfoLoader ?? PackageInfo.fromPlatform,
       _feedUrlOverride = feedUrlOverride;

  static Future<void> _defaultInstallerLauncher(String exePath) async {
    await Process.start('cmd', [
      '/c',
      'start',
      '',
      exePath,
      '/SILENT',
      '/CLOSEAPPLICATIONS',
      '/RESTARTAPPLICATIONS',
    ], mode: ProcessStartMode.detached);
  }

  Future<UpdateInfo?> checkForUpdates() async {
    final configuredFeedUrl = _feedUrlOverride ?? EnvConfig.updateFeedUrl;
    final String releaseUrl;
    if (configuredFeedUrl.isNotEmpty) {
      releaseUrl = configuredFeedUrl;
    } else {
      final owner = EnvConfig.githubOwner;
      final repo = EnvConfig.githubRepo;

      if (owner.isEmpty || repo.isEmpty) {
        AppLogger.info(_logTag, 'Check skipped: no release feed configured');
        return null;
      }
      releaseUrl =
          'https://api.github.com/repos/$owner/$repo/releases?per_page=50';
    }

    final packageInfo = await _packageInfoLoader();
    final currentVersion = packageInfo.version;
    AppLogger.info(
      _logTag,
      'Check started: current=$currentVersion '
      'source=${configuredFeedUrl.isNotEmpty ? 'feed' : 'github'} '
      'host=${Uri.tryParse(releaseUrl)?.host}',
    );

    try {
      String? nextUrl = releaseUrl;
      var pagesFetched = 0;
      var hasTruncatedHistory = false;
      final parsedReleases = <_ParsedRelease>[];

      while (nextUrl != null && pagesFetched < _maxPages) {
        final response = await _dio.get<dynamic>(nextUrl);

        if (response.statusCode != 200) {
          AppLogger.warning(
            _logTag,
            'Check got status=${response.statusCode} page=${pagesFetched + 1}',
          );
          if (pagesFetched == 0) return null;
          break;
        }

        pagesFetched++;
        final rawData = response.data;
        final bool isListResponse;
        final List<dynamic> rawItems;

        if (rawData is Map<String, dynamic>) {
          isListResponse = false;
          rawItems = [rawData];
        } else if (rawData is List<dynamic>) {
          isListResponse = true;
          rawItems = rawData;
        } else {
          AppLogger.warning(
            _logTag,
            'Check got unexpected payload type=${rawData.runtimeType} '
            'page=$pagesFetched',
          );
          if (pagesFetched == 1) return null;
          break;
        }

        final pageParsed = <_ParsedRelease>[];
        for (final item in rawItems) {
          if (item is! Map<String, dynamic>) continue;
          final parsed = _parseRelease(item);
          if (parsed != null) {
            pageParsed.add(parsed);
          }
        }
        parsedReleases.addAll(pageParsed);

        if (!isListResponse || rawItems.isEmpty) {
          break;
        }

        final nextLink = _extractNextPageUrl(response.headers);
        if (nextLink == null) {
          break;
        }

        final hasReachedCurrentOrOlder = pageParsed.any(
          (r) => UpdateInfo.compareVersions(r.version, currentVersion) <= 0,
        );
        if (hasReachedCurrentOrOlder) {
          break;
        }

        if (pagesFetched >= _maxPages) {
          hasTruncatedHistory = true;
          break;
        }

        nextUrl = nextLink;
      }

      if (parsedReleases.isEmpty) {
        AppLogger.info(_logTag, 'Check result: no published releases found');
        return null;
      }

      parsedReleases.sort(
        (a, b) => UpdateInfo.compareVersions(b.version, a.version),
      );

      final latest = parsedReleases.first;
      final releaseHistory = parsedReleases
          .where(
            (r) => UpdateInfo.compareVersions(r.version, currentVersion) > 0,
          )
          .map(
            (r) => ReleaseNoteEntry(
              version: r.version,
              notes: r.notes,
              publishedAt: r.publishedAt,
            ),
          )
          .toList(growable: false);

      final info = UpdateInfo(
        latestVersion: latest.version,
        currentVersion: currentVersion,
        downloadUrl: latest.downloadUrl,
        checksumUrl: latest.checksumUrl,
        releaseNotes: latest.notes,
        publishedAt: latest.publishedAt,
        releaseHistory: releaseHistory,
        hasTruncatedHistory: hasTruncatedHistory,
      );
      AppLogger.info(
        _logTag,
        'Check result: current=$currentVersion latest=${info.latestVersion} '
        'hasUpdate=${info.hasUpdate} '
        'silentInstall=${info.supportsSilentInstall} '
        'newerVersions=${releaseHistory.length} pages=$pagesFetched '
        'truncated=$hasTruncatedHistory',
      );
      return info;
    } catch (e, st) {
      debugPrint('Erro ao verificar atualizações: $e');
      AppLogger.warning(_logTag, 'Check failed', error: e, stackTrace: st);
      return null;
    }
  }

  _ParsedRelease? _parseRelease(Map<String, dynamic> data) {
    if (data['draft'] == true || data['prerelease'] == true) {
      return null;
    }

    final rawTag = data['tag_name'];
    if (rawTag is! String || rawTag.trim().isEmpty) {
      return null;
    }
    final version = rawTag.trim().replaceFirst(RegExp(r'^[vV]'), '');
    if (version.isEmpty) return null;

    final publishedAtRaw =
        (data['published_at'] as String?) ?? (data['created_at'] as String?);
    if (publishedAtRaw == null) return null;
    final publishedAt = DateTime.tryParse(publishedAtRaw);
    if (publishedAt == null) return null;

    final rawNotes = (data['body'] as String?) ?? '';

    String? downloadUrl;
    String? checksumUrl;
    final assets = data['assets'] as List<dynamic>?;
    if (assets != null) {
      for (final asset in assets) {
        if (asset is! Map<String, dynamic>) continue;
        final name = (asset['name'] as String?)?.toLowerCase();
        final browserUrl = asset['browser_download_url'] as String?;
        if (name == null || browserUrl == null) continue;
        if (downloadUrl == null && name.endsWith('.exe')) {
          downloadUrl = browserUrl;
        } else if (checksumUrl == null && name.endsWith('.sha256')) {
          checksumUrl = browserUrl;
        }
      }
    }
    downloadUrl ??= (data['html_url'] as String?) ?? '';

    return _ParsedRelease(
      version: version,
      notes: _cleanReleaseNotes(rawNotes),
      publishedAt: publishedAt,
      downloadUrl: downloadUrl,
      checksumUrl: checksumUrl,
    );
  }

  static String? _extractNextPageUrl(Headers headers) {
    final linkValues = headers['link'];
    if (linkValues == null || linkValues.isEmpty) return null;
    final combined = linkValues.join(',');
    final match = RegExp(
      r'<([^>]+)>[^,]*;\s*rel="next"',
      caseSensitive: false,
    ).firstMatch(combined);
    return match?.group(1);
  }

  Future<void> downloadAndInstall(
    UpdateInfo updateInfo, {
    void Function(double? progress)? onProgress,
    void Function(UpdateInstallStage stage)? onStageChange,
  }) async {
    AppLogger.info(
      _logTag,
      'Install started: ${updateInfo.currentVersion} -> '
      '${updateInfo.latestVersion}',
    );
    if (!_isWindows) {
      AppLogger.warning(_logTag, 'Install aborted: not running on Windows');
      throw const UpdateInstallException(
        'Atualização automática disponível apenas no Windows.',
      );
    }
    final checksumUrl = updateInfo.checksumUrl;
    if (checksumUrl == null || checksumUrl.isEmpty) {
      AppLogger.warning(_logTag, 'Install aborted: release has no .sha256');
      throw const UpdateInstallException(
        'Arquivo de verificação SHA-256 não encontrado nesta versão.',
      );
    }

    onStageChange?.call(UpdateInstallStage.downloading);
    final Response<String> checksumResponse;
    try {
      checksumResponse = await _dio.get<String>(
        checksumUrl,
        options: Options(responseType: ResponseType.plain),
      );
    } catch (e, st) {
      AppLogger.error(
        _logTag,
        'Checksum download failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
    final expectedHash = _parseSha256(checksumResponse.data);
    if (expectedHash == null) {
      AppLogger.error(_logTag, 'Checksum file has invalid format');
      throw const UpdateInstallException(
        'Formato inválido no arquivo de verificação SHA-256.',
      );
    }

    final dir = _tempDirectory ?? Directory.systemTemp;
    final savePath =
        '${dir.path}${Platform.pathSeparator}workshop_update_${DateTime.now().millisecondsSinceEpoch}.exe';
    final installerFile = File(savePath);
    AppLogger.info(_logTag, 'Checksum fetched; installer download started');
    final stopwatch = Stopwatch()..start();
    var lastLoggedBucket = -1;
    var loggedUnknownSize = false;

    try {
      await _dio.download(
        updateInfo.downloadUrl,
        savePath,
        options: Options(receiveTimeout: const Duration(minutes: 5)),
        onReceiveProgress: (received, total) {
          if (total <= 0) {
            if (!loggedUnknownSize) {
              loggedUnknownSize = true;
              AppLogger.info(_logTag, 'Download progress: size unknown');
            }
            onProgress?.call(null);
          } else {
            final fraction = (received / total).clamp(0.0, 1.0);
            final bucket = (fraction * 4).floor();
            if (bucket > lastLoggedBucket) {
              lastLoggedBucket = bucket;
              AppLogger.info(
                _logTag,
                'Download progress: ${bucket * 25}% ($received/$total bytes)',
              );
            }
            onProgress?.call(fraction);
          }
        },
      );

      AppLogger.info(
        _logTag,
        'Download completed in ${stopwatch.elapsedMilliseconds}ms',
      );

      onStageChange?.call(UpdateInstallStage.verifying);
      final digest = await sha256.bind(installerFile.openRead()).first;
      final actualHash = digest.toString().toLowerCase();
      if (actualHash != expectedHash) {
        AppLogger.error(_logTag, 'SHA-256 verification failed');
        throw const UpdateInstallException(
          'Falha na verificação de integridade (SHA-256) do instalador.',
        );
      }

      AppLogger.info(_logTag, 'SHA-256 verification ok');

      onStageChange?.call(UpdateInstallStage.launching);
      AppLogger.info(_logTag, 'Launching installer');
      await _installerLauncher(savePath);
      AppLogger.info(_logTag, 'Installer launched; exiting app');
      await AppLogger.flush().timeout(
        const Duration(seconds: 2),
        onTimeout: () {},
      );
      _onExit();
    } catch (e, st) {
      AppLogger.error(_logTag, 'Install failed', error: e, stackTrace: st);
      if (await installerFile.exists()) {
        try {
          await installerFile.delete();
        } catch (_) {}
      }
      rethrow;
    }
  }

  static String? _parseSha256(String? content) {
    if (content == null) return null;
    final match = RegExp(r'\b([a-fA-F0-9]{64})\b').firstMatch(content);
    return match?.group(1)?.toLowerCase();
  }

  Future<void> openDownloadUrl(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      throw Exception('Não foi possível abrir o link de download');
    }
  }

  String _cleanReleaseNotes(String rawNotes) {
    var result = rawNotes.replaceAll('\r\n', '\n').trimLeft();

    // Remove cabeçalho redundante de versão gerado pelo workflow de release
    // (ex: "## v1.6.0\n\n").
    result = result
        .replaceFirst(
          RegExp(r'^#{1,6}\s+v?\d+\.\d+\.\d+[^\n]*\n*', caseSensitive: false),
          '',
        )
        .trimLeft();

    // Remove cabeçalho redundante "Novidades" (ex: "### Novidades\n\n").
    result = result
        .replaceFirst(
          RegExp(r'^#{1,6}\s+novidades\s*(?:\n+|$)', caseSensitive: false),
          '',
        )
        .trimLeft();

    final cleaned = _stripMarkdown(result);
    return cleaned.isEmpty ? _emptyNotesFallback : cleaned;
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
