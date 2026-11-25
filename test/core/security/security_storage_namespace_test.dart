import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/security/security_storage.dart';

/// Keyring stand-in: answers the calls SecurityStorage makes.
class _FakeKeyring implements FlutterSecureStorage {
  final Map<String, String> values = {};

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final key = invocation.namedArguments[#key] as String?;
    switch (invocation.memberName) {
      case #write:
        values[key!] = invocation.namedArguments[#value] as String;
        return Future<void>.value();
      case #read:
        return Future<String?>.value(values[key]);
      case #delete:
        values.remove(key);
        return Future<void>.value();
      case #deleteAll:
        values.clear();
        return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  late _FakeKeyring keyring;

  setUp(() {
    keyring = _FakeKeyring()
      ..values.addAll({
        'api_key': 'developer-key',
        'access_token': 'developer-access',
        'bound_device_id': 'machine-id',
      });
  });

  test('a namespace never reads or overwrites the default setup', () async {
    final agent = SecurityStorage(namespace: 'agent', storage: keyring);

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
      final agent = SecurityStorage(namespace: 'agent', storage: keyring);

      expect(await agent.getBoundDeviceId(), 'machine-id');
    },
  );

  test('clearAll in a namespace only drops its key and tokens', () async {
    final agent = SecurityStorage(namespace: 'agent', storage: keyring);
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
    await SecurityStorage(storage: keyring).clearAll();

    expect(keyring.values, isEmpty);
  });
}
