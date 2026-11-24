import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/config/app_config.dart';

void main() {
  group('AppConfig.validateBaseUrl', () {
    test('aceita https em release e em debug', () {
      for (final release in [true, false]) {
        final uri = AppConfig.validateBaseUrl(
          'https://api.eletroluk.com',
          isReleaseMode: release,
        );
        expect(uri.scheme, 'https');
        expect(uri.host, 'api.eletroluk.com');
      }
    });

    test('rejeita http em host remoto em release', () {
      expect(
        () => AppConfig.validateBaseUrl(
          'http://api.eletroluk.com',
          isReleaseMode: true,
        ),
        throwsA(isA<AppConfigException>()),
      );
    });

    test('rejeita http em host remoto mesmo fora do release', () {
      expect(
        () => AppConfig.validateBaseUrl(
          'http://api.eletroluk.com',
          isReleaseMode: false,
        ),
        throwsA(isA<AppConfigException>()),
      );
    });

    test('aceita http://localhost e http://127.0.0.1 em debug', () {
      for (final url in ['http://localhost:8080', 'http://127.0.0.1:8080']) {
        expect(
          AppConfig.validateBaseUrl(url, isReleaseMode: false).scheme,
          'http',
          reason: url,
        );
      }
    });

    test('rejeita http://localhost e http://127.0.0.1 em release', () {
      for (final url in ['http://localhost:8080', 'http://127.0.0.1:8080']) {
        expect(
          () => AppConfig.validateBaseUrl(url, isReleaseMode: true),
          throwsA(isA<AppConfigException>()),
          reason: url,
        );
      }
    });

    test('rejeita URL vazia ou malformada', () {
      for (final release in [true, false]) {
        for (final url in [
          '',
          '   ',
          'api.eletroluk.com',
          '/api',
          'https://',
          'ftp://api.eletroluk.com',
          'ws://localhost:8080',
          'http://[::1',
        ]) {
          expect(
            () => AppConfig.validateBaseUrl(url, isReleaseMode: release),
            throwsA(isA<AppConfigException>()),
            reason: '"$url" release=$release',
          );
        }
      }
    });
  });

  group('AppConfig.fromValues', () {
    test('normaliza os valores e expõe a baseUri validada', () {
      final config = AppConfig.fromValues(
        baseUrl: ' https://api.eletroluk.com ',
        devApiKey: ' dev-key ',
        updateFeedUrl: ' https://feed.test/latest.json ',
        githubOwner: ' org ',
        githubRepo: ' repo ',
        isReleaseMode: false,
        isDebugMode: true,
      );

      expect(config.baseUri, Uri.parse('https://api.eletroluk.com'));
      expect(config.devApiKey, 'dev-key');
      expect(config.updateFeedUrl, 'https://feed.test/latest.json');
      expect(config.githubOwner, 'org');
      expect(config.githubRepo, 'repo');
    });

    test('descarta DEV_API_KEY fora do debug', () {
      final config = AppConfig.fromValues(
        baseUrl: 'https://api.eletroluk.com',
        devApiKey: 'dev-key',
        isReleaseMode: true,
      );

      expect(config.devApiKey, isEmpty);
    });

    test('BASE_URL inválida falha na criação, com mensagem acionável', () {
      expect(
        () => AppConfig.fromValues(baseUrl: '', isReleaseMode: false),
        throwsA(
          isA<AppConfigException>().having(
            (e) => e.message,
            'message',
            contains('--dart-define-from-file'),
          ),
        ),
      );
    });
  });
}
