import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/services/update/update_service.dart';

UpdateInfo _makeInfo({required String latest, required String current}) {
  return UpdateInfo(
    latestVersion: latest,
    currentVersion: current,
    downloadUrl: 'https://example.com/setup.exe',
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
}
