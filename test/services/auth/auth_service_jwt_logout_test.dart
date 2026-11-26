import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/security/auth_notifier.dart';
import 'package:flutter_workshop_front/services/auth/auth_service.dart';

import '../../support/http/stub_http_client_adapter.dart';
import '../../support/memory_security_storage.dart';

void main() {
  group('AuthService — JWT roles & logout', () {
    late MemorySecurityStorage storage;
    late AuthService authService;

    setUp(() {
      storage = MemorySecurityStorage(boundDeviceIdFallback: 'test-bound-id');
      authService = AuthService(
        dio: testDio(StubHttpClientAdapter.fixed()),
        storage: storage,
        authNotifier: AuthNotifier(),
        appVersion: () async => '1.1.1',
      );
    });

    test('identifica ADMIN corretamente via JWT', () async {
      // Payload: {"roles":["ADMIN"],"exp":9999999999}
      const adminToken =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlcyI6WyJBRE1JTiJdLCJleHAiOjk5OTk5OTk5OTl9.signature';

      await storage.saveAccessToken(adminToken);

      expect(await authService.isAdmin, isTrue);
    });

    test('identifica USER padrão corretamente via JWT', () async {
      // Payload: {"roles":["USER"],"exp":9999999999}
      const userToken =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlcyI6WyJVU0VSIl0sImV4cCI6OTk5OTk5OTk5OX0.signature';

      await storage.saveAccessToken(userToken);

      expect(await authService.isAdmin, isFalse);
    });

    test('logout limpa tokens de sessão e API key', () async {
      await storage.saveApiKey('123');
      await storage.saveTokens('abc', 'def');
      expect(await storage.getApiKey(), isNotNull);

      await authService.logout();

      expect(await storage.getApiKey(), isNull);
      expect(await storage.getAccessToken(), isNull);
    });
  });
}
