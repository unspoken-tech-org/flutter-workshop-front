import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/config/app_config.dart';
import 'package:flutter_workshop_front/core/di/app_dependencies.dart';
import 'package:flutter_workshop_front/core/security/auth_notifier.dart';

import '../../support/in_memory_secure_key_value_store.dart';

void main() {
  AppConfig config() => AppConfig.fromValues(
    baseUrl: 'https://api.test',
    devApiKey: 'dev-key',
    isReleaseMode: false,
    isDebugMode: true,
  );

  test(
    'monta o grafo sem estado global: duas instâncias são independentes',
    () {
      final a = AppDependencies.create(config(), InMemorySecureKeyValueStore());
      final b = AppDependencies.create(config(), InMemorySecureKeyValueStore());

      expect(identical(a.authService, b.authService), isFalse);
      expect(identical(a.storage, b.storage), isFalse);

      a.authNotifier.setState(AuthRouteState.authenticated, notify: false);
      expect(b.authNotifier.state, isNot(AuthRouteState.authenticated));
    },
  );

  test('credenciais gravadas pelo storage vão para o store injetado', () async {
    final store = InMemorySecureKeyValueStore();
    final deps = AppDependencies.create(config(), store);

    await deps.storage.saveApiKey('key-1');

    expect(store.values['api_key'], 'key-1');
    expect(await deps.authService.apiKey, 'key-1');
  });

  test('UpdateService é único: a checagem do boot vale para o drawer', () {
    final deps = AppDependencies.create(
      config(),
      InMemorySecureKeyValueStore(),
    );

    deps.updateService.hasCheckedOnStartup = true;

    expect(deps.updateService.hasCheckedOnStartup, isTrue);
  });
}
