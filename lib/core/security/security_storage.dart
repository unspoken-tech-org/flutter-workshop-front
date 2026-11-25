import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class SecurityStorage {
  /// [namespace] prefixes the API key and the tokens (`<namespace>.api_key`),
  /// so a debug run for agents or E2E (`Config.storageNamespace`) never reads
  /// or overwrites the setup of the developer's own runs, which share the same
  /// keyring. The `bound_device_id` is not namespaced: it identifies the
  /// machine, and the API binds a key to the first device that uses it.
  SecurityStorage({
    String namespace = '',
    FlutterSecureStorage storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(),
      wOptions: WindowsOptions(),
    ),
  }) : _storage = storage,
       _kApiKey = _key(namespace, 'api_key'),
       _kAccessToken = _key(namespace, 'access_token'),
       _kRefreshToken = _key(namespace, 'refresh_token'),
       _namespaced = namespace.isNotEmpty;

  final FlutterSecureStorage _storage;
  final String _kApiKey;
  final String _kAccessToken;
  final String _kRefreshToken;
  final bool _namespaced;

  static const _kBoundDeviceId = 'bound_device_id';

  static String _key(String namespace, String name) =>
      namespace.isEmpty ? name : '$namespace.$name';

  Future<void> saveApiKey(String key) async {
    await _storage.write(key: _kApiKey, value: key);
  }

  Future<String?> getApiKey() async {
    return await _storage.read(key: _kApiKey);
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: _kAccessToken, value: accessToken);
    await _storage.write(key: _kRefreshToken, value: refreshToken);
  }

  Future<void> saveAccessToken(String accessToken) async {
    await _storage.write(key: _kAccessToken, value: accessToken);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _kAccessToken);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _kRefreshToken);
  }

  Future<String> getBoundDeviceId() async {
    String? boundDeviceId = await _storage.read(key: _kBoundDeviceId);
    if (boundDeviceId == null) {
      boundDeviceId = const Uuid().v4();
      await _storage.write(key: _kBoundDeviceId, value: boundDeviceId);
    }
    return boundDeviceId;
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
  }

  Future<void> clearProvisioning({bool removeBoundDeviceId = false}) async {
    await clearSession();
    await _storage.delete(key: _kApiKey);
    if (removeBoundDeviceId) {
      await _storage.delete(key: _kBoundDeviceId);
    }
  }

  /// Deletes the whole store, or, with a namespace, only that namespace's
  /// API key and tokens.
  Future<void> clearAll() async {
    if (!_namespaced) {
      await _storage.deleteAll();
      return;
    }
    await clearProvisioning();
  }
}
