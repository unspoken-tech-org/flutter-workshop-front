import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class SecurityStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
    wOptions: WindowsOptions(),
  );

  static const _kApiKey = 'api_key';
  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kBoundDeviceId = 'bound_device_id';

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
    await _storage.delete(key: _kApiKey);
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
