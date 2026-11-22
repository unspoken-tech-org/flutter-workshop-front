import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/services/update/update_service.dart';
import 'package:flutter_workshop_front/widgets/shared/update_dialog.dart';

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
