import 'package:flutter_workshop_front/core/security/secure_key_value_store.dart';
import 'package:uuid/uuid.dart';

/// Credenciais do aparelho (api key, tokens, `bound_device_id`) sobre um
/// [SecureKeyValueStore].
class SecurityStorage {
  /// [namespace] prefixes the API key and the tokens (`<namespace>.api_key`),
  /// so a debug run for agents or E2E (`AppConfig.storageNamespace`) never
  /// reads or overwrites the setup of the developer's own runs, which share
  /// the same keyring. The `bound_device_id` is not namespaced: it identifies
  /// the machine, and the API binds a key to the first device that uses it.
  SecurityStorage(this._storage, {String namespace = ''})
    : _kApiKey = _key(namespace, 'api_key'),
      _kAccessToken = _key(namespace, 'access_token'),
      _kRefreshToken = _key(namespace, 'refresh_token'),
      _namespaced = namespace.isNotEmpty;

  final SecureKeyValueStore _storage;
  final String _kApiKey;
  final String _kAccessToken;
  final String _kRefreshToken;
  final bool _namespaced;

  static const _kBoundDeviceId = 'bound_device_id';

  static String _key(String namespace, String name) =>
      namespace.isEmpty ? name : '$namespace.$name';

  Future<void> saveApiKey(String key) async {
    await _storage.write(_kApiKey, key);
  }

  Future<String?> getApiKey() async {
    return await _storage.read(_kApiKey);
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(_kAccessToken, accessToken);
    await _storage.write(_kRefreshToken, refreshToken);
  }

  Future<void> saveAccessToken(String accessToken) async {
    await _storage.write(_kAccessToken, accessToken);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(_kAccessToken);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(_kRefreshToken);
  }

  Future<String> getBoundDeviceId() async {
    String? boundDeviceId = await _storage.read(_kBoundDeviceId);
    if (boundDeviceId == null) {
      boundDeviceId = const Uuid().v4();
      await _storage.write(_kBoundDeviceId, boundDeviceId);
    }
    return boundDeviceId;
  }

  Future<void> clearSession() async {
    await _storage.delete(_kAccessToken);
    await _storage.delete(_kRefreshToken);
  }

  Future<void> clearProvisioning({bool removeBoundDeviceId = false}) async {
    await clearSession();
    await _storage.delete(_kApiKey);
    if (removeBoundDeviceId) {
      await _storage.delete(_kBoundDeviceId);
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
