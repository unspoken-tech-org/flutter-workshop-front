import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/logging/app_logger.dart';
import 'package:flutter_workshop_front/core/logging/log_sink.dart';
import 'package:flutter_workshop_front/services/update/update_service.dart';
import 'package:flutter_workshop_front/widgets/shared/update_dialog.dart';
import 'package:package_info_plus/package_info_plus.dart';

class _FeedAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final payload = jsonEncode({
      'tag_name': 'v1.6.0',
      'body': '## Novidades\n\n- Auto-update',
      'published_at': '2026-11-22T12:00:00Z',
      'html_url': 'https://example.com/release',
      'assets': [
        {
          'name': 'Workshop.App-Setup-1.6.0.exe',
          'browser_download_url': 'http://192.168.122.1:8787/setup.exe',
        },
        {
          'name': 'Workshop.App-Setup-1.6.0.exe.sha256',
          'browser_download_url': 'http://192.168.122.1:8787/setup.exe.sha256',
        },
      ],
    });
    return ResponseBody.fromString(
      payload,
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _DynamicFeedAdapter implements HttpClientAdapter {
  final Map<String, ({Object body, Map<String, List<String>> headers})>
  responses;
  final List<String> requestedUrls = [];

  _DynamicFeedAdapter(this.responses);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final url = options.uri.toString();
    requestedUrls.add(url);
    final entry = responses[url];
    if (entry == null) {
      return ResponseBody.fromString('Not Found', 404);
    }
    return ResponseBody.fromString(
      jsonEncode(entry.body),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
        ...entry.headers,
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _releaseJson({
  String? tagName,
  String? body,
  String publishedAt = '2026-11-22T12:00:00Z',
  bool draft = false,
  bool prerelease = false,
  String? exeUrl,
  String? shaUrl,
  String htmlUrl = 'https://example.com/release',
}) {
  final assets = <Map<String, dynamic>>[];
  if (exeUrl != null) {
    assets.add({'name': 'Workshop-Setup.exe', 'browser_download_url': exeUrl});
  }
  if (shaUrl != null) {
    assets.add({
      'name': 'Workshop-Setup.exe.sha256',
      'browser_download_url': shaUrl,
    });
  }
  return {
    if (tagName != null) 'tag_name': tagName,
    'body': body,
    'published_at': publishedAt,
    'draft': draft,
    'prerelease': prerelease,
    'html_url': htmlUrl,
    'assets': assets,
  };
}

class _FakeUpdateAdapter implements HttpClientAdapter {
  final Uint8List exeBytes;
  final String sha256Body;

  _FakeUpdateAdapter({required this.exeBytes, required this.sha256Body});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.uri.path.endsWith('.sha256')) {
      final bytes = utf8.encode(sha256Body);
      return ResponseBody.fromBytes(
        bytes,
        200,
        headers: {
          Headers.contentTypeHeader: ['text/plain'],
        },
      );
    }
    return ResponseBody.fromBytes(
      exeBytes,
      200,
      headers: {
        Headers.contentTypeHeader: ['application/octet-stream'],
        Headers.contentLengthHeader: ['${exeBytes.length}'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

UpdateInfo? _infoOf(UpdateCheckResult result) {
  expect(result, isA<UpdateCheckCompleted>());
  return (result as UpdateCheckCompleted).info;
}

class _StatusAdapter implements HttpClientAdapter {
  final int statusCode;
  final Map<String, List<String>> headers;

  _StatusAdapter(this.statusCode, {this.headers = const {}});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    '{"message":"error"}',
    statusCode,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
      ...headers,
    },
  );

  @override
  void close({bool force = false}) {}
}

class _OfflineAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => throw DioException.connectionError(
    requestOptions: options,
    reason: 'offline',
  );

  @override
  void close({bool force = false}) {}
}

class _MemorySink implements LogSink {
  final List<String> lines = [];

  @override
  String? get directoryPath => null;

  @override
  void write(String line) => lines.add(line);

  @override
  Future<void> flush() async {}
}

UpdateInfo _makeInfo({
  required String latest,
  required String current,
  String? checksumUrl,
}) {
  return UpdateInfo(
    latestVersion: latest,
    currentVersion: current,
    downloadUrl: 'https://example.com/setup.exe',
    checksumUrl: checksumUrl,
    releaseNotes: 'notes',
    publishedAt: DateTime(2026, 11, 22),
  );
}

void main() {
  group('UpdateInfo version comparison', () {
    test('stable release is newer than pre-release of same version', () {
      expect(
        _makeInfo(latest: '1.2.0', current: '1.2.0-test').hasUpdate,
        isTrue,
      );
      expect(
        _makeInfo(latest: '1.2.0', current: '1.2.0-rc.1').hasUpdate,
        isTrue,
      );
      expect(
        _makeInfo(latest: '1.2.0-test', current: '1.2.0').hasUpdate,
        isFalse,
      );
    });

    test('compares pre-release identifiers with SemVer precedence', () {
      expect(
        _makeInfo(latest: '1.2.0-rc.2', current: '1.2.0-rc.1').hasUpdate,
        isTrue,
      );
      expect(
        _makeInfo(latest: '1.2.0-rc.10', current: '1.2.0-rc.2').hasUpdate,
        isTrue,
      );
      expect(
        _makeInfo(latest: '1.2.0-beta', current: '1.2.0-alpha').hasUpdate,
        isTrue,
      );
    });

    test('compares build metadata only when both versions include it', () {
      expect(
        _makeInfo(latest: '1.2.0+2', current: '1.2.0+1').hasUpdate,
        isTrue,
      );
      expect(
        _makeInfo(latest: '1.2.0+1', current: '1.2.0+2').hasUpdate,
        isFalse,
      );
      expect(_makeInfo(latest: '1.5.2', current: '1.5.2+1').hasUpdate, isFalse);
    });

    test('handles v prefix and standard major/minor/patch bumps', () {
      expect(_makeInfo(latest: 'v1.5.3', current: '1.5.2').hasUpdate, isTrue);
      expect(_makeInfo(latest: '1.5.2', current: '1.5.2').hasUpdate, isFalse);
      expect(_makeInfo(latest: '1.5.1', current: '1.5.2').hasUpdate, isFalse);
    });
  });

  group('UpdateService.checkForUpdates', () {
    test(
      'uses custom feedUrlOverride and parses exe and sha256 assets',
      () async {
        final dio = Dio()..httpClientAdapter = _FeedAdapter();
        final service = UpdateService(
          dio: dio,
          feedUrlOverride: 'http://192.168.122.1:8787/latest.json',
          packageInfoLoader: () async => PackageInfo(
            appName: 'Workshop App',
            packageName: 'workshop',
            version: '1.5.9',
            buildNumber: '1',
          ),
        );

        final info = _infoOf(await service.checkForUpdates());

        expect(info, isNotNull);
        expect(info!.latestVersion, '1.6.0');
        expect(info.currentVersion, '1.5.9');
        expect(info.hasUpdate, isTrue);
        expect(info.downloadUrl, 'http://192.168.122.1:8787/setup.exe');
        expect(info.checksumUrl, 'http://192.168.122.1:8787/setup.exe.sha256');
        expect(info.releaseNotes, '- Auto-update');
        expect(info.releaseHistory, hasLength(1));
        expect(info.releaseHistory.first.version, '1.6.0');
        expect(info.releaseHistory.first.notes, '- Auto-update');
        expect(info.hasTruncatedHistory, isFalse);
      },
    );

    test(
      'parses multiple releases, filters drafts/prereleases/old, and sorts by SemVer',
      () async {
        const url =
            'https://api.github.com/repos/org/repo/releases?per_page=50';
        final adapter = _DynamicFeedAdapter({
          url: (
            body: [
              _releaseJson(
                tagName: 'v1.4.0',
                body: '## v1.4.0\n\n### Novidades\n\n- Recurso 1.4',
                publishedAt: '2026-11-20T10:00:00Z',
                exeUrl: 'https://example.com/1.4.0.exe',
              ),
              _releaseJson(
                tagName: 'v1.6.0-rc.1',
                body: 'Prerelease',
                prerelease: true,
              ),
              _releaseJson(
                tagName: 'v1.7.0',
                body: 'Draft release',
                draft: true,
              ),
              _releaseJson(body: 'Missing tag_name'),
              _releaseJson(
                tagName: 'v1.5.0',
                body: '## v1.5.0\n\n### Novidades\n\n- Recurso 1.5',
                publishedAt: '2026-11-22T12:00:00Z',
                exeUrl: 'https://example.com/1.5.0.exe',
                shaUrl: 'https://example.com/1.5.0.exe.sha256',
              ),
              _releaseJson(
                tagName: 'v1.3.0',
                body: 'Current version',
                publishedAt: '2026-11-18T10:00:00Z',
              ),
              _releaseJson(
                tagName: 'v1.2.0',
                body: 'Older version',
                publishedAt: '2026-11-15T10:00:00Z',
              ),
            ],
            headers: const {},
          ),
        });

        final dio = Dio()..httpClientAdapter = adapter;
        final service = UpdateService(
          dio: dio,
          feedUrlOverride: url,
          packageInfoLoader: () async => PackageInfo(
            appName: 'Workshop App',
            packageName: 'workshop',
            version: '1.3.0',
            buildNumber: '1',
          ),
        );

        final info = _infoOf(await service.checkForUpdates());

        expect(info, isNotNull);
        expect(info!.latestVersion, '1.5.0');
        expect(info.hasUpdate, isTrue);
        expect(info.downloadUrl, 'https://example.com/1.5.0.exe');
        expect(info.checksumUrl, 'https://example.com/1.5.0.exe.sha256');
        expect(info.hasTruncatedHistory, isFalse);
        expect(info.releaseHistory.map((e) => e.version).toList(), [
          '1.5.0',
          '1.4.0',
        ]);
        expect(info.releaseHistory[0].notes, '- Recurso 1.5');
        expect(info.releaseHistory[1].notes, '- Recurso 1.4');
      },
    );

    test(
      'returns up-to-date UpdateInfo with empty releaseHistory when current >= latest',
      () async {
        const url =
            'https://api.github.com/repos/org/repo/releases?per_page=50';
        final adapter = _DynamicFeedAdapter({
          url: (
            body: [
              _releaseJson(
                tagName: 'v1.5.0',
                body: '## v1.5.0\n\n### Novidades\n\n- Atual',
                publishedAt: '2026-11-22T12:00:00Z',
                exeUrl: 'https://example.com/1.5.0.exe',
              ),
              _releaseJson(
                tagName: 'v1.4.0',
                body: 'Antiga',
                publishedAt: '2026-11-20T12:00:00Z',
              ),
            ],
            headers: const {},
          ),
        });

        final dio = Dio()..httpClientAdapter = adapter;
        final service = UpdateService(
          dio: dio,
          feedUrlOverride: url,
          packageInfoLoader: () async => PackageInfo(
            appName: 'Workshop App',
            packageName: 'workshop',
            version: '1.5.0',
            buildNumber: '1',
          ),
        );

        final info = _infoOf(await service.checkForUpdates());

        expect(info, isNotNull);
        expect(info!.hasUpdate, isFalse);
        expect(info.latestVersion, '1.5.0');
        expect(info.releaseHistory, isEmpty);
        expect(info.hasTruncatedHistory, isFalse);
      },
    );

    test(
      'strips redundant version and Novidades headings and falls back when empty',
      () async {
        const url =
            'https://api.github.com/repos/org/repo/releases?per_page=50';
        final adapter = _DynamicFeedAdapter({
          url: (
            body: [
              _releaseJson(
                tagName: 'v2.2.0',
                body:
                    '## v2.2.0\r\n\r\n### Novidades\r\n\r\n- **Novo** relatório\r\n\r\n### Correções\r\n\r\n- Ajuste no filtro',
              ),
              _releaseJson(
                tagName: 'v2.1.0',
                body: '## v2.1.0\n\n### Novidades\n\n   ',
              ),
              _releaseJson(tagName: 'v2.0.1', body: null),
            ],
            headers: const {},
          ),
        });

        final dio = Dio()..httpClientAdapter = adapter;
        final service = UpdateService(
          dio: dio,
          feedUrlOverride: url,
          packageInfoLoader: () async => PackageInfo(
            appName: 'Workshop App',
            packageName: 'workshop',
            version: '2.0.0',
            buildNumber: '1',
          ),
        );

        final info = _infoOf(await service.checkForUpdates());

        expect(info, isNotNull);
        expect(info!.releaseHistory, hasLength(3));
        expect(
          info.releaseHistory[0].notes,
          '- Novo relatório\n\nCorreções\n\n- Ajuste no filtro',
        );
        expect(info.releaseHistory[1].notes, 'Sem notas de atualização');
        expect(info.releaseHistory[2].notes, 'Sem notas de atualização');
      },
    );

    test(
      'paginates via Link header and stops once currentVersion is reached',
      () async {
        const page1 =
            'https://api.github.com/repos/org/repo/releases?per_page=50';
        const page2 =
            'https://api.github.com/repos/org/repo/releases?per_page=50&page=2';
        const page3 =
            'https://api.github.com/repos/org/repo/releases?per_page=50&page=3';

        final adapter = _DynamicFeedAdapter({
          page1: (
            body: [
              _releaseJson(tagName: 'v1.4.0', body: 'Notas 1.4'),
              _releaseJson(tagName: 'v1.3.0', body: 'Notas 1.3'),
            ],
            headers: {
              'link': ['<$page2>; rel="next", <$page3>; rel="last"'],
            },
          ),
          page2: (
            body: [
              _releaseJson(tagName: 'v1.2.0', body: 'Notas 1.2'),
              _releaseJson(tagName: 'v1.1.0', body: 'Notas 1.1'),
            ],
            headers: {
              'link': ['<$page3>; rel="next"'],
            },
          ),
          page3: (
            body: [_releaseJson(tagName: 'v1.0.0', body: 'Notas 1.0')],
            headers: const {},
          ),
        });

        final dio = Dio()..httpClientAdapter = adapter;
        final service = UpdateService(
          dio: dio,
          feedUrlOverride: page1,
          packageInfoLoader: () async => PackageInfo(
            appName: 'Workshop App',
            packageName: 'workshop',
            version: '1.1.0',
            buildNumber: '1',
          ),
        );

        final info = _infoOf(await service.checkForUpdates());

        expect(info, isNotNull);
        expect(adapter.requestedUrls, [page1, page2]);
        expect(info!.hasTruncatedHistory, isFalse);
        expect(info.releaseHistory.map((e) => e.version).toList(), [
          '1.4.0',
          '1.3.0',
          '1.2.0',
        ]);
      },
    );

    test(
      'caps pagination at 3 pages and marks hasTruncatedHistory when more pages remain',
      () async {
        const page1 =
            'https://api.github.com/repos/org/repo/releases?per_page=50';
        const page2 =
            'https://api.github.com/repos/org/repo/releases?per_page=50&page=2';
        const page3 =
            'https://api.github.com/repos/org/repo/releases?per_page=50&page=3';
        const page4 =
            'https://api.github.com/repos/org/repo/releases?per_page=50&page=4';

        final adapter = _DynamicFeedAdapter({
          page1: (
            body: [_releaseJson(tagName: 'v1.5.0', body: 'Notas 1.5')],
            headers: {
              'link': ['<$page2>; rel="next"'],
            },
          ),
          page2: (
            body: [_releaseJson(tagName: 'v1.4.0', body: 'Notas 1.4')],
            headers: {
              'link': ['<$page3>; rel="next"'],
            },
          ),
          page3: (
            body: [_releaseJson(tagName: 'v1.3.0', body: 'Notas 1.3')],
            headers: {
              'link': ['<$page4>; rel="next"'],
            },
          ),
          page4: (
            body: [_releaseJson(tagName: 'v1.2.0', body: 'Notas 1.2')],
            headers: const {},
          ),
        });

        final dio = Dio()..httpClientAdapter = adapter;
        final service = UpdateService(
          dio: dio,
          feedUrlOverride: page1,
          packageInfoLoader: () async => PackageInfo(
            appName: 'Workshop App',
            packageName: 'workshop',
            version: '1.0.0',
            buildNumber: '1',
          ),
        );

        final info = _infoOf(await service.checkForUpdates());

        expect(info, isNotNull);
        expect(adapter.requestedUrls, [page1, page2, page3]);
        expect(info!.hasTruncatedHistory, isTrue);
        expect(info.releaseHistory.map((e) => e.version).toList(), [
          '1.5.0',
          '1.4.0',
          '1.3.0',
        ]);
      },
    );
  });

  group('UpdateService.checkForUpdates result', () {
    late _MemorySink sink;

    setUp(() {
      sink = _MemorySink();
      AppLogger.setSinkForTesting(sink);
    });

    tearDown(() => AppLogger.setSinkForTesting(const NoopLogSink()));

    UpdateService serviceWith(HttpClientAdapter adapter, {String? feed}) =>
        UpdateService(
          dio: Dio()..httpClientAdapter = adapter,
          feedUrlOverride: feed ?? 'https://api.github.com/repos/o/r/releases',
          packageInfoLoader: () async => PackageInfo(
            appName: 'Workshop App',
            packageName: 'workshop',
            version: '1.0.0',
            buildNumber: '1',
          ),
        );

    test('is disabled when no feed is configured', () async {
      final result = await serviceWith(
        _OfflineAdapter(),
        feed: '',
      ).checkForUpdates();

      expect(result, isA<UpdateCheckDisabled>());
    });

    test('reports GitHub rate limit (403 with no remaining quota)', () async {
      final result = await serviceWith(
        _StatusAdapter(
          403,
          headers: {
            'x-ratelimit-remaining': ['0'],
            'x-ratelimit-reset': ['1795536000'],
          },
        ),
      ).checkForUpdates();

      expect(result, isA<UpdateCheckFailed>());
      final failed = result as UpdateCheckFailed;
      expect(failed.reason, UpdateCheckFailureReason.rateLimited);
      expect(failed.statusCode, 403);
      expect(
        sink.lines.last,
        contains(
          'Check failed: rate limited status=403 remaining=0 '
          'resetAt=2026-11-24T16:00:00.000Z',
        ),
      );
    });

    test('reports 429 as rate limit', () async {
      final result = await serviceWith(_StatusAdapter(429)).checkForUpdates();

      expect(
        (result as UpdateCheckFailed).reason,
        UpdateCheckFailureReason.rateLimited,
      );
    });

    test('a 403 with quota left is a bad status, not rate limit', () async {
      final result = await serviceWith(
        _StatusAdapter(
          403,
          headers: {
            'x-ratelimit-remaining': ['42'],
          },
        ),
      ).checkForUpdates();

      final failed = result as UpdateCheckFailed;
      expect(failed.reason, UpdateCheckFailureReason.badStatus);
      expect(failed.statusCode, 403);
      expect(sink.lines.last, contains('Check failed: status=403'));
    });

    test('reports server errors as bad status', () async {
      final result = await serviceWith(_StatusAdapter(502)).checkForUpdates();

      final failed = result as UpdateCheckFailed;
      expect(failed.reason, UpdateCheckFailureReason.badStatus);
      expect(failed.statusCode, 502);
    });

    test('reports network failures and logs them', () async {
      final result = await serviceWith(_OfflineAdapter()).checkForUpdates();

      expect(
        (result as UpdateCheckFailed).reason,
        UpdateCheckFailureReason.network,
      );
      expect(
        sink.lines.last,
        contains('WARNING [Update] Check failed: network type=connectionError'),
      );
    });

    test('completes with no info when the feed has no release', () async {
      const url = 'https://example.com/releases';
      final result = await serviceWith(
        _DynamicFeedAdapter({url: (body: <Object>[], headers: {})}),
        feed: url,
      ).checkForUpdates();

      expect(result, isA<UpdateCheckCompleted>());
      expect((result as UpdateCheckCompleted).info, isNull);
    });
  });

  group('UpdateService release notes', () {
    Future<String> notesFor(String body) async {
      const url = 'https://example.com/latest.json';
      final adapter = _DynamicFeedAdapter({
        url: (body: _releaseJson(tagName: 'v2.0.0', body: body), headers: {}),
      });
      final service = UpdateService(
        dio: Dio()..httpClientAdapter = adapter,
        feedUrlOverride: url,
        packageInfoLoader: () async => PackageInfo(
          appName: 'Workshop App',
          packageName: 'workshop',
          version: '1.0.0',
          buildNumber: '1',
        ),
      );
      final info = _infoOf(await service.checkForUpdates());
      return info!.releaseNotes;
    }

    test('keeps underscores inside names', () async {
      expect(
        await notesFor('- Corrige device_customer_id e update_service.dart'),
        '- Corrige device_customer_id e update_service.dart',
      );
      expect(
        await notesFor('- Usa MAX__SIZE e A_B_C'),
        '- Usa MAX__SIZE e A_B_C',
      );
    });

    test('still strips underscore emphasis', () async {
      expect(
        await notesFor('- _Importante_: veja __aqui__ (ação_rápida)'),
        '- Importante: veja aqui (ação_rápida)',
      );
    });
  });

  group('UpdateService.downloadAndInstall', () {
    test('verifies SHA-256, launches installer, and exits on match', () async {
      final tempDir = await Directory.systemTemp.createTemp('update_test_ok_');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final exeBytes = Uint8List.fromList(utf8.encode('fake-installer-binary'));
      final expectedHash = sha256.convert(exeBytes).toString();
      final dio = Dio()
        ..httpClientAdapter = _FakeUpdateAdapter(
          exeBytes: exeBytes,
          sha256Body: '$expectedHash  Workshop App-Setup-1.5.3.exe',
        );

      String? launchedPath;
      var exited = false;
      final stages = <UpdateInstallStage>[];
      final progresses = <double?>[];

      final service = UpdateService(
        dio: dio,
        tempDirectory: tempDir,
        isWindows: true,
        installerLauncher: (path) async {
          launchedPath = path;
        },
        onExit: () => exited = true,
      );

      await service.downloadAndInstall(
        _makeInfo(
          latest: '1.5.3',
          current: '1.5.2',
          checksumUrl: 'https://example.com/setup.exe.sha256',
        ),
        onProgress: progresses.add,
        onStageChange: stages.add,
      );

      expect(launchedPath, isNotNull);
      expect(File(launchedPath!).existsSync(), isTrue);
      expect(exited, isTrue);
      expect(stages, [
        UpdateInstallStage.downloading,
        UpdateInstallStage.verifying,
        UpdateInstallStage.launching,
      ]);
      expect(progresses.last, 1.0);
    });

    test(
      'deletes downloaded file and aborts when SHA-256 mismatches',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'update_test_bad_',
        );
        addTearDown(() async {
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        });

        final exeBytes = Uint8List.fromList(utf8.encode('tampered-binary'));
        final wrongHash = '0' * 64;
        final dio = Dio()
          ..httpClientAdapter = _FakeUpdateAdapter(
            exeBytes: exeBytes,
            sha256Body: '$wrongHash  setup.exe',
          );

        var launched = false;
        var exited = false;
        final service = UpdateService(
          dio: dio,
          tempDirectory: tempDir,
          isWindows: true,
          installerLauncher: (_) async => launched = true,
          onExit: () => exited = true,
        );

        await expectLater(
          service.downloadAndInstall(
            _makeInfo(
              latest: '1.5.3',
              current: '1.5.2',
              checksumUrl: 'https://example.com/setup.exe.sha256',
            ),
          ),
          throwsA(isA<UpdateInstallException>()),
        );

        expect(launched, isFalse);
        expect(exited, isFalse);
        expect(tempDir.listSync(), isEmpty);
      },
    );
  });

  group('UpdateDialog', () {
    testWidgets('shows browser fallback when silent install fails', (
      tester,
    ) async {
      var browserOpened = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateDialog(
              updateInfo: _makeInfo(
                latest: '1.5.3',
                current: '1.5.2',
                checksumUrl: 'https://example.com/setup.exe.sha256',
              ),
              onDownload: () => browserOpened = true,
              onSilentInstall: ({onProgress, onStageChange}) async {
                throw const UpdateInstallException('Falha de rede');
              },
            ),
          ),
        ),
      );

      expect(find.text('Atualizar Agora'), findsOneWidget);
      await tester.tap(find.text('Atualizar Agora'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Falha de rede'), findsOneWidget);
      expect(find.text('Abrir no Navegador'), findsOneWidget);

      await tester.tap(find.text('Abrir no Navegador'));
      await tester.pumpAndSettle();
      expect(browserOpened, isTrue);
    });
  });
}
