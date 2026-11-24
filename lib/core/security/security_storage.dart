import 'package:flutter_workshop_front/core/security/secure_key_value_store.dart';
import 'package:uuid/uuid.dart';

/// Credenciais do aparelho (api key, tokens, `bound_device_id`) sobre um
/// [SecureKeyValueStore].
class SecurityStorage {
  SecurityStorage(this._storage);

  final SecureKeyValueStore _storage;

  static const _kApiKey = 'api_key';
  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kBoundDeviceId = 'bound_device_id';

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

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
