import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/security/security_storage.dart';

import '../../support/in_memory_secure_key_value_store.dart';

void main() {
  late InMemorySecureKeyValueStore keyring;

  setUp(() {
    keyring = InMemorySecureKeyValueStore()
      ..values.addAll({
        'api_key': 'developer-key',
        'access_token': 'developer-access',
        'bound_device_id': 'machine-id',
      });
  });

  test('a namespace never reads or overwrites the default setup', () async {
    final agent = SecurityStorage(keyring, namespace: 'agent');

    expect(await agent.getApiKey(), isNull);
    await agent.saveApiKey('agent-key');
    await agent.saveTokens('agent-access', 'agent-refresh');

    expect(keyring.values['api_key'], 'developer-key');
    expect(keyring.values['access_token'], 'developer-access');
    expect(keyring.values['agent.api_key'], 'agent-key');
    expect(await agent.getAccessToken(), 'agent-access');
  });

  test(
    'the bound device id is shared: the key is bound to the machine',
    () async {
      final agent = SecurityStorage(keyring, namespace: 'agent');

      expect(await agent.getBoundDeviceId(), 'machine-id');
    },
  );

  test('clearAll in a namespace only drops its key and tokens', () async {
    final agent = SecurityStorage(keyring, namespace: 'agent');
    await agent.saveApiKey('agent-key');
    await agent.saveTokens('agent-access', 'agent-refresh');

    await agent.clearAll();

    expect(keyring.values, {
      'api_key': 'developer-key',
      'access_token': 'developer-access',
      'bound_device_id': 'machine-id',
    });
  });

  test('without a namespace, clearAll wipes the store', () async {
    await SecurityStorage(keyring).clearAll();

    expect(keyring.values, isEmpty);
  });
}
