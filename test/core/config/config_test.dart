import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/config/config.dart';

void main() {
  group('Config.validateBaseUrl', () {
    test('aceita https em release e em debug', () {
      for (final release in [true, false]) {
        final uri = Config.validateBaseUrl(
          'https://api.eletroluk.com',
          isReleaseMode: release,
        );
        expect(uri.scheme, 'https');
        expect(uri.host, 'api.eletroluk.com');
      }
    });

    test('rejeita http em host remoto em release', () {
      expect(
        () => Config.validateBaseUrl(
          'http://api.eletroluk.com',
          isReleaseMode: true,
        ),
        throwsStateError,
      );
    });

    test('rejeita http em host remoto mesmo fora do release', () {
      expect(
        () => Config.validateBaseUrl(
          'http://api.eletroluk.com',
          isReleaseMode: false,
        ),
        throwsStateError,
      );
    });

    test('aceita http://localhost e http://127.0.0.1 em debug', () {
      for (final url in ['http://localhost:8080', 'http://127.0.0.1:8080']) {
        expect(
          Config.validateBaseUrl(url, isReleaseMode: false).scheme,
          'http',
          reason: url,
        );
      }
    });

    test('rejeita http://localhost e http://127.0.0.1 em release', () {
      for (final url in ['http://localhost:8080', 'http://127.0.0.1:8080']) {
        expect(
          () => Config.validateBaseUrl(url, isReleaseMode: true),
          throwsStateError,
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
            () => Config.validateBaseUrl(url, isReleaseMode: release),
            throwsStateError,
            reason: '"$url" release=$release',
          );
        }
      }
    });
  });
}
